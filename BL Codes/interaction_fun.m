function F = interaction_fun(x0)
%% Load Initial Data Sets
load('aero_variables.mat','Uinf','Vinf','nu');
load('wing_geom.mat','xi_d','zi_d','si_d','xj_d','zj_d','sj_d','xi_s','zi_s','si_s','xj_s','zj_s','sj_s','n_com','t_com','Na','Nw','Naw');
load('influences.mat','B','C','sigma');
load('edgevel.mat','v_tang');

% disp('load successful')
mdef = x0(:,1);
muj  = x0(1:Naw,2);
theta= x0(:,3);


t_com=t_com;
% %% Calculate Mass Defect Influence Matrix
%     for i = 1:Naw
%         for j = 1:Naw
%             num = B(i,j)-B(i,j-1);
%             den = xj_s(j-1)-xj_s(j);
%             A(i,j) = num/den;
%         end
%     end
%     A(:,1)=A(:,Na);
for i=1:Naw
    sig(i,1)=(mdef(i+1)-mdef(i))/(xj_s(i)-xj_s(i+1));
end
% Sig
% funk

    Q1 =(B*sig)+(C*muj)+(B*sigma);
    
    for i = 1:Naw
        Vt=0;
        Vn=0;
    for j=1:Naw
        [ud,wd]=doublet_2Dc(muj(j),xi_d(i),zi_d(i),xj_d(j),zj_d(j),xj_d(j+1),zj_d(j+1));
        [us,ws]=source_2Dc(sig(j),xi_d(i),zi_d(i),xj_d(j),zj_d(j),xj_d(j+1),zj_d(j+1));
        Vt=Vt-ud-us;
        Vn=Vn-wd-ws;
    end
    Vt=Vt+Uinf;
    Vn=Vn+Vinf;
    Uei(i,1)=[Vt Vn]*t_com(:,i);
    end

%% Extrapolate to Model Velocity at Panel End Nodes    
    dif = sqrt((xi_d(1)-xj_d(1))^2+(zi_d(1)-zj_d(1))^2);
    Uej = ppval(pchip(si_d+dif,Uei),sj_d);

%% Calculate Change in Velocity 
    delUEI = calc_delUEI(Uej);

%% Calculate Average Velocity     
    avgUEI = calc_avgUEI(Uej);

%% Calculate Displacement Thickness 
    dstar = mdef./Uei;

%% Calculate Shape Factor 
    Hi = dstar./theta;

%% Extrapolate to Model Shape Factor at Panel End Nodes    
    Hj = ppval(pchip(si_d+dif,Hi),sj_d);
    
%% Calculate Average Shape Factor
    avgH = calc_avgH(Hj);

%% Calculate Kinetic Energy Shape Factor 
    Hstari = calc_hstar(Hi);

%% Extrapolate Kinetic Shape for End Nodes
    Hstarj = ppval(pchip(si_d+dif,Hstari),sj_d);

%% Calculate Change in Kinetic Energy Shape Factor
    delHS = calc_delHS(Hstarj);

%% Calculate Avergae Kinetic Energy Shape Factor
    avgHS = calc_avgHS(Hstarj);
   
%% Calculate Momentum Thickness at Panel Nodes
    thetaj = ppval(pchip(si_d+dif,theta),sj_d);

%% Calculate Change in Momentum Thickness
    delTHT = calc_delTHT(thetaj);

%% Calculate Average Momentum Thickness
    avgTHT = calc_avgTHT(thetaj);

%% Calculate Momentum Thickness Dependent Reynolds Number
    Re_THT = (Uej.*thetaj)/nu;

%% Calculate Coefficient of Friction
    cf_2 = calc_cf(Hj);
    cf_2 = (1./Re_THT').*cf_2;

%% Calculate Average Coefficient of Friction
    avgCF2 = calc_avgCF2(cf_2);

% Calculate Node Spacing
    delX = calc_delX(xj_d);

% Calculate Residual Equation R1
    R1 = (delTHT./avgTHT)+((avgH+2).*(delUEI./avgUEI))-(avgCF2.*(delX./avgTHT));

% Calculate Dissipation Coefficient divided by Hstar
    dcHS = calc_DCHstar(Hj);
   
    dc_Hstar = (1./Re_THT').*dcHS;

% Calculate Average Dissipation Coefficient divided by Hstar
    avgDCH = calc_avgDCH(dc_Hstar);

% Calculate R2
    R2 = (delHS./avgHS)+((1-avgH).*(delUEI./avgUEI))+((avgCF2-avgDCH).*(delX./avgTHT));

%% Store Solution
F = zeros(160);

F(1,1:length(R1)) = R1;
F(2,1:length(R2)) = R2;
F(3,1:length(Q1)) = Q1;

% plot(1:160,F(1,:),'-r',1:160,F(2,:),'-b',1:160,F(3,:),'-g')

end