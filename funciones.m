x=[0:0.1:20];

muA=((1+x/5).^3).^-1;
muB=(1+3*(x-5).^2).^-1;

plot(x,muA)
plot(x,muB)

muA_neg=1-((1+x/5).^3).^-1;
muB_neg=1-(1+3*(x-5).^2).^-1;

plot(x,muA_neg)
plot(x,muB_neg)

A_union_B=max(muA,muB)
plot(x,A_union_B)

A_interseccion_B=min(muA,muB)
plot(x,A_interseccion_B)

A_neg_union_B_neg=max(muA_neg,muB_neg)
plot(x,A_neg_union_B_neg)

A_neg_inters_B_neg=min(muA_neg,muB_neg)
plot(x,A_neg_inters_B_neg)

A_inters_A_neg=min(muA,muA_neg)
plot(x,A_inters_A_neg)

B_inters_B_neg=min(muB,muB_neg)
plot(x,B_inters_B_neg)



