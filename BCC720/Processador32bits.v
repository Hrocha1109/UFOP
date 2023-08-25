module ULA(
    input clk, // Sinal de clock
    input fase,
    input enable,
    input [31:0] operand_A,
    input [31:0] operand_B,
    input [2:0]  ULAOp, // 3 bits para suportar as operações
    output reg [31:0] result,
    output [1:0] flags
);
   assign flags[0] = ~(|result); //redução em "OR"
   assign flags[1] = result[31];


always @(posedge clk) // Detecta a borda de subida do sinal de clock
begin
    if(fase && enable)
    begin
        case (ULAOp)
            3'b000: result <= operand_A + operand_B; // ADD operation
            3'b001: result <= operand_A - operand_B; // SUBTRACT operation
            3'b010: result <= operand_A * operand_B; // MULTIPLY operation
            3'b011: result <= operand_A / operand_B; // DIVISION operation
            3'b100: result <= operand_A & operand_B; // AND operation
            3'b101: result <= operand_A | operand_B; // OR operation
            3'b110: result <= ~operand_A;            // NOT operation
            default: result <= 0; // Operação inválida
        endcase
    end




end




endmodule




module UnidadeControle(
    input clk, // Sinal de clock
    input fase, // Sinal de Fase
    input [2:0] opcode, // Código de operação da instrução
    output reg opULA, // Código de operação para a ULA
    output reg opBranch, // Controle de salto condicional
    output reg opLoadCte,
    output reg opMov,
    output reg opLS
);




always @(posedge clk)
     begin
    if(fase)
      case(opcode)
        0: {opBranch,opULA,opLoadCte,opMov,opLS} <= 5'b01000;
        1: {opBranch,opULA,opLoadCte,opMov,opLS} <= 5'b10000;
      2: {opBranch,opULA,opLoadCte,opMov,opLS} <= 5'b00001;
      6: {opBranch,opULA,opLoadCte,opMov,opLS} <= 5'b00100;  
        //4: {opBranch,opULA,opLoadCte,opMov,opLS} <= 5'b00001;
        default: {opBranch,opULA,opLoadCte,opMov,opLS} <= 5'b00000;
      endcase
     end
endmodule




module JumpModule(
  input [2:0] op,
   input [1:0] flags,
   input enable,
   input fase,
   input clk,
   output reg desvio_tomado
);




always @(posedge clk)
begin
  if(enable && fase)
       desvio_tomado=(
       ((op==6)&&(flags[0]))||
       ((op==1)&&(~flags[0]))||
       ((op==2)&&(~flags[1]))||
       ((op==3)&&(flags[1]))||
       ((op==4)&&((flags[0])||(~flags[1])))||
       ((op==5)&&((flags[0])||(flags[1])))||
       (op==0))?1:0;
else desvio_tomado=0;
end




endmodule




module LoadCte(op,cte,saida,clk,enable,fase,valor_inicial);


   input [2:0] op;
   input clk, enable,fase;
   input [15:0] cte;
   input [31:0] valor_inicial;
   output reg [31:0] saida;
   always @(posedge clk)
     begin
    if((enable) && (fase)) saida = (op)?{valor_inicial[31:16],cte}:
                                            {cte,valor_inicial[15:0]};
     end




endmodule


module BancoReg(regD, reg0, reg1, saida1, saida2, saidaLdCte,entrada, clk, enable,fase);


   input [7:0] regD, reg0,reg1;
   input [31:0] entrada;
   input clk, enable,fase;
   output [31:0] saida1, saida2, saidaLdCte;


   reg [31:0] registradores[0:127];
   initial
     begin
     registradores[0] =0;
     registradores[1] =0;
     registradores[2] =0;
     registradores[3] =0;
    end
   assign saida1 = registradores[reg0];
   assign saida2 = registradores[reg1];
   assign saidaLdCte = registradores[regD];
 
   always @(posedge clk)
     begin
  if(~enable && fase) registradores[regD] <= entrada;
     end


endmodule

module LS(opLS,en,oper,inf1,inf2,fase,enMemLS,mbrIN,mar,opMem,clk);

input opLS,en,oper,fase,clk;
input [31:0] inf1,inf2;
output reg enMemLS;
output reg opMem;
output reg [31:0] mbrIN,mar;



initial
  begin
     enMemLS = 0;
     opMem = 0;
  end
  
always @(posedge clk)
  begin
    if(opLS && ~en)
      begin
        mar <= inf1;
        enMemLS <= 1;
        opMem <= oper;
        if(oper)  mbrIN <= inf2;
      end
    else 
      begin
        enMemLS <=0;
        opMem <= 0;
      end
end

endmodule


module Processador(opMem,mar,mbrOUT,mbrIN,mem_enable,pinos_input,clk);


   input [31:0] mbrOUT,pinos_input;
   input clk;
   output [31:0] mar,mar1;
   output wire mem_enable, opMem;
   output [31:0] mbrIN;


   reg [31:0] PC, IR;
   reg [5:0] fases; //mem,buscaI,decod,buscaO,exec,writeback
   
   wire [31:0] w01,w02,w03,w04,w05,w07,w08,w09,w10,w11,w12,w13,w14;
   wire [1:0] w06;
   wire desvio_tomado,opULA_,opLoadCte_,opBranch_,opMov_,enMemLS_;


   assign mar = (enMemLS_)?mar1:PC;
   assign w02 = PC;
   assign mem_enable = fases[5] || enMemLS_;
   assign w01 = (desvio_tomado)?w04:w03;
   assign w03 = w02 + 1;
   assign w04 = w02 + {{6{IR[25]}},IR[25:0]};
   assign w05 = (opULA_)?w07:w08;
   assign w08 = (opLoadCte_)?w11:w13;
   //assign w13 = ((opMov_)&&(IR[24]))?w14:w09;
   assign w13 = ((opLS))?mbrOUT:pinos_input;
   
   initial
     begin
  PC = 0;
  fases = 6'b000001;
     end


   always @(negedge clk)
     begin
  fases <= {fases[0],fases[5:1]};
     end
   
   always @(posedge clk)
     begin
     if(fases[4]) IR <= mbrOUT;
     end


   always @(posedge clk)
     begin
  if(fases[0]) PC <= w01;
     end


        UnidadeControle uc(.opcode(IR[31:29]),.opBranch(opBranch_),.opULA(opULA_),
       .opLoadCte(opLoadCte_),.opMov(opMov_),.clk(clk),.fase(fases[3]),.opLS(opLS));
   ULA ula(.operand_A(w09),.operand_B(w10),.result(w07),.ULAOp(IR[31:29]),.clk(clk),
     .flags(w06),.enable(opULA_),.fase(fases[1]));
   LoadCte lc(.op(IR[28:26]),.cte(IR[17:2]),.saida(w11),.clk(clk),
        .enable(opLoadCte_),.fase(fases[1]),.valor_inicial(w12));
   JumpModule ub(.op(IR[28:26]),.flags(w06),.enable(opBranch_),.fase(fases[1]),.clk(clk),.desvio_tomado(desvio_tomado));
   BancoReg br(.regD(IR[25:18]),.reg0(IR[17:10]),.reg1(IR[9:2]),.saida1(w09), .saidaLdCte(w12),
         .saida2(w10),.entrada(w05),.clk(clk),.enable(opBranch_),
         .fase(fases[0]));
   LS ls(.opLS(opLS),.en(IR[28]),.oper(IR[26]),.inf1(w09),.inf2(w12),.fase(fases[1]),.enMemLS(enMemLS_),.mbrIN(mbrIN),.opMem(opMem),.clk(clk),.mar(mar1));
endmodule


module Memoria (mar,mbrIN,mbrOUT,enable,clk,op);


   input [31:0] mar;
   input  enable, clk,op;   //op=0 leitura; op=1 Escrita
   input  [31:0] mbrIN;
   output reg [31:0] mbrOUT;


   reg [31:0] mem[0:1024];
 
   initial
     begin


    mem[0]=32'b00100000000000000000000000000011;
    mem[1]=32'b00000000000000000000000000000001;
    mem[2]=32'b00000000000000000000000000001111;
    mem[3]=32'b110000000000000000000000000000XX;
    mem[4]=32'b110001000000000000000000000001XX;
    mem[5]=32'b0100000000000100000000XXXXXXXXXX;
    mem[6]=32'b110001000000000000000000000010XX;
    mem[7]=32'b0100000000001000000000XXXXXXXXXX;
    mem[8]=32'b010101000000110000000000000000XX;
    mem[9]=32'b000000000001010000000100000010XX;
    mem[10]=32'b000001000001000000001100000101XX;
    mem[11]=32'b00110100000000000000000000001111;
    mem[12]=32'b0100010000000000000101XXXXXXXXXX;
    mem[13]=32'b01010100000000XXXXXXXXXXXXXXXXXX;
    mem[14]=32'b00100000000000000000000000010010;
    mem[15]=32'b110001000000000000000000000001XX;
    mem[16]=32'b0100010000000000000100XXXXXXXXXX;
    mem[17]=32'b010101000000000000000000000000XX;
    mem[18]=32'b00100000000000000000000000000000;


     end
   
   always @(posedge clk)
     begin
  if(enable)
    if (!op) mbrOUT <= mem[mar];
    else mem[mar]=mbrIN;
     end
endmodule


module top;


   reg clk;
   reg [31:0] t_pinos_input;
   
   wire [31:0] t_mar,t_mbrIN,t_mbrOUT;
   wire t_enable,opMem;
   
   initial
     begin
  clk = 0;
  t_pinos_input = 10; //valor qualquer...
     end


   initial
     begin
      #216 $finish;
     end


   always
     begin
    #1 clk = ~clk;
     end


   initial
     begin
$display("opMem fase\topULA,opLoadCte,opBranch,opMov\tPC\tIR\tReg0\tReg1\tReg2\tReg3\tReg4\tReg5");
 /* $monitor("%b\t%b\t%b\t%b\t%b\t%d\t%b\t%d\t%d\t%d\t%d\t%d\t%d",p.IR,p.fases,p.uc.opULA,p.uc.opLoadCte,
                 p.uc.opBranch,p.uc.opMov,p.PC,p.IR,
                 p.br.registradores[0],p.br.registradores[1],
                 p.br.registradores[2],p.br.registradores[3],
                 p.br.registradores[4], p.br.registradores[5]);*/
    $monitor("%b %d %d %d %d %d",p.IR,p.PC,p.br.registradores[0],p.br.registradores[1],p.br.registradores[2],p.w13);
     end


   Memoria mem(.mar(t_mar),.mbrOUT(t_mbrOUT),.enable(t_enable),.clk(clk),.op(opMem),.mbrIN(t_mbrIN)); //falta colocar o mbrIN
   Processador p(.mar(t_mar),.mbrOUT(t_mbrOUT),.mem_enable(t_enable),
     .pinos_input(t_pinos_input),.clk(clk),.opMem(opMem));


endmodule
