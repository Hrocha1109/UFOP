
param n, integer; /* numero de nos */
param m, integer; /* numero de pseudo-depositos */
param L, integer; /* minimo de vertices visitados por viajantes */
param U, integer; /* maximo de vertices visitados por viajantes */
set V := 1..n; /* conjunto de nos */
set D := (n+1)..(n+m); /* conjunto de pseudo-depositos */
param c{V,V}; /* distancia do no i ao no j */
var x{V union D,V union D,D}, binary; /* x[i,j,k] = 1 se o caixeiro viajante que originou de k for do no i para j */
var y{V,V,D}, binary; /* ultimo caminho que cada viajante vai tomar */
var t{V}, integer; /* momento em que vertice V[i] e visitado */

#1
#minimize total: sum{i in V, j in V} c[i,j] * sum{k in D} (x[i,j,k] + x[i,k,k]*x[k,i,j]);
minimize total: sum{i in V, j in V} c[i,j] * sum{k in D} (x[i,j,k] + y[i,j,k]);

#2
s.t. saida{k in D}: sum{j in V} x[k,j,k] = 1;
#3
s.t. visita{j in V}: sum{k in D} x[k,j,k] + sum{k in D, i in V} x[i,j,k] = 1;
#4
s.t. continuidade_1{k in D, j in V}: x[k,j,k] + sum{i in V} x[i,j,k] - x[j,k,k] - sum{i in V} x[j,i,k] = 0;
#5
s.t. continuidade_2{k in D}: sum{j in V} x[k,j,k] - sum{j in V} x[j,k,k] = 0;
#6
s.t. limites_1{i in V}: t[i] + (U-2) * sum{k in D} x[k,i,k] - sum{k in D} x[i,k,k] <= U-1;
#7
s.t. limites_2{i in V}: t[i] + sum{k in D} x[k,i,k] + (2-L)*sum{k in D} x[i,k,k] >= 2;
#8
s.t. viagem_de_volta{i in V}: sum{k in D} x[k,i,k] + sum{k in D} x[i,k,k] <=1;
#9
s.t. SEC{i in V, j in V}: t[i] - t[j] + U * sum{k in D}x[i,j,k] + (U-2) * sum{k in D} x[j,i,k] <= U-1;
#16
s.t. linearizacao_1{i in V, j in V, k in D}: y[i,j,k] >= x[i,k,k] + x[k,j,k] -1;
#17
s.t. linearizacao_2{i in V, j in V, k in D}: y[i,j,k] <= x[k,j,k];
#18
s.t. linearizacao_3{i in V, j in V, k in D}: y[i,j,k] <= x[i,k,k];

data;
param n := 8;
param m := 2;
param L := 3;
param U :=5;


param c:
		   1   2   3   4   5   6   7   8:=
		1  0  400 316 424 412 500 700 806
		2 400  0  424 316 500 412 806 700
		3 316 424  0  200 100 223 412 500
		4 424 316 200  0  223 100 500 412
		5 412 500 100 223  0  200 316 424
		6 500 412 223 100 200  0  424 316
		7 700 806 412 500 316 424  0  400
		8 806 700 500 412 424 316 400  0;

/*
param c:
		   1   2   3   4   5   6   7   8:=
		1  0  260 177 307 437 339 335 301
		2 379  0  545 692 659 186 251 251
		3 220 349  0  173 155 481 199 665
		4 602 114 550  0  244 520 571 234
		5 650 597 546 126  0  124 337 389
		6 583 596 276 193 572  0  443 531
		7 308 239 347 327 315 674  0  526
		8 594 225 461 106 115 498 603  0;
*/
end;








