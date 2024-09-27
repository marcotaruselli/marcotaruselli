function PolPCACovMatrix(data,fs)

% Attivare gli assi con i segnali plottati
global mainPolFig
asse = findobj(mainPolFig,'type','axes','tag','comp_x');
set(asse,'visible','on')
dataObjs = get(asse, 'Children');
dataObjs.LineStyle = '-';
asse = findobj(mainPolFig,'type','axes','tag','comp_y');
set(asse,'visible','on')
dataObjs = get(asse, 'Children');
dataObjs.LineStyle = '-';
asse = findobj(mainPolFig,'type','axes','tag','comp_z');
set(asse,'visible','on')
dataObjs = get(asse, 'Children');
dataObjs.LineStyle = '-';

%% PRINCIPAL COMPONENT ANALYSIS -------------------------------------------
% [coeff,score,latent,tsquared,explained,mu] = pca(data);
[coeff,score,latent,~,explained,~] = pca(data);
% % Rotation of the PCA eigenvectors ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% rotatedCoeffV = rotatefactors(coeff(:,1:2));
% rotatedCoeffP = rotatefactors(coeff(:,1:3),'Method','promax');


%% FIGURES WITH HODOGRAMS AND EIGENVECTORS --------------------------------

% delete(findobj(gcf,'type','axes'));
% delete(findobj(gcf,'type','polaraxes'))

% scaleFactor = 1e6;                                                          % Unit conversione from [m/s] to [mum/s]
% axLimit = 1.5e-7*scaleFactor;
% Figure with eigenvectors not scaled ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% data = data*scaleFactor;
axLimit = max(abs(data(:)));
axes('units','normalized','position',[.2 .3 .3 .3],'FontUnits','points','fontsize',8,'FontName','Arial')
plot(data(:,1),data(:,2),'color',[.7 .7 .7]);
hold on
hleg(1) = plot([-axLimit axLimit],(coeff(2,1)/coeff(1,1))*[-axLimit axLimit],'-r','linewidth',2);
hleg(2) = plot([-axLimit axLimit],(coeff(2,2)/coeff(1,2))*[-axLimit axLimit],'--g','linewidth',2);
hleg(3) = plot([-axLimit axLimit],(coeff(2,3)/coeff(1,3))*[-axLimit axLimit],':b','linewidth',2);
% hleg(1) = plot([-coeff(1,1) coeff(1,1)],[-coeff(2,1) coeff(2,1)],'-r','linewidth',2);
% hleg(2) = plot([-coeff(1,2) coeff(1,2)],[-coeff(2,2) coeff(2,2)],'--g','linewidth',2);
% hleg(3) = plot([-coeff(1,3) coeff(1,3)],[-coeff(2,3) coeff(2,3)],':b','linewidth',2);
% % Rotated eigenvectors
% plot([-rotatedCoeffV(1,1,I) rotatedCoeffV(1,1,I)],[-rotatedCoeffV(2,1,I) rotatedCoeffV(2,1,I)],'--r','linewidth',1);
% plot([-rotatedCoeffV(1,2,I) rotatedCoeffV(1,2,I)],[-rotatedCoeffV(2,2,I) rotatedCoeffV(2,2,I)],'--g','linewidth',1);
% %     plot([-rotatedCoeff(1,3,I) rotatedCoeff(1,3,I)],[-rotatedCoeff(2,3,I) rotatedCoeff(2,3,I)],'--b','linewidth',1);
% plot([-rotatedCoeffP(1,1,I) rotatedCoeffP(1,1,I)],[-rotatedCoeffP(2,1,I) rotatedCoeffP(2,1,I)],':r','linewidth',2);
% plot([-rotatedCoeffP(1,2,I) rotatedCoeffP(1,2,I)],[-rotatedCoeffP(2,2,I) rotatedCoeffP(2,2,I)],':g','linewidth',2);
% plot([-rotatedCoeffP(1,3,I) rotatedCoeffP(1,3,I)],[-rotatedCoeffP(2,3,I) rotatedCoeffP(2,3,I)],':b','linewidth',2);
hold off
axis equal
set(gca,'xlim',[-axLimit axLimit],'ylim',[-axLimit axLimit],'FontUnits','points','fontsize',7,'FontName','Arial')
xlabel('\bfE [\mum/s]');ylabel('\bfN  [\mum/s]');
legend(hleg,['Expl. Var: ' num2str(explained(1),'%2.1f') '%'],[num2str(explained(2),'%2.1f') '%'],[num2str(explained(3),'%2.1f') '%'],'location','north')

axes('units','normalized','position',[.45 .3 .3 .3],'FontUnits','points','fontsize',8,'FontName','Arial')
plot(data(:,1),data(:,3),'color',[.7 .7 .7]);
hold on
plot([-axLimit axLimit],(coeff(3,1)/coeff(1,1))*[-axLimit axLimit],'-r','linewidth',2);
plot([-axLimit axLimit],(coeff(3,2)/coeff(1,2))*[-axLimit axLimit],'--g','linewidth',2);
plot([-axLimit axLimit],(coeff(3,3)/coeff(1,3))*[-axLimit axLimit],':b','linewidth',2);
% % Rotated eigenvectors
% plot([-rotatedCoeffV(1,1,I) rotatedCoeffV(1,1,I)],[-rotatedCoeffV(3,1,I) rotatedCoeffV(3,1,I)],'--r','linewidth',1);
% plot([-rotatedCoeffV(1,2,I) rotatedCoeffV(1,2,I)],[-rotatedCoeffV(3,2,I) rotatedCoeffV(3,2,I)],'--g','linewidth',1);
% %     plot([-rotatedCoeff(1,3,I) rotatedCoeff(1,3,I)],[-rotatedCoeff(3,3,I) rotatedCoeff(3,3,I)],'--b','linewidth',1);
% plot([-rotatedCoeffP(1,1,I) rotatedCoeffP(1,1,I)],[-rotatedCoeffP(3,1,I) rotatedCoeffP(3,1,I)],':r','linewidth',2);
% plot([-rotatedCoeffP(1,2,I) rotatedCoeffP(1,2,I)],[-rotatedCoeffP(3,2,I) rotatedCoeffP(3,2,I)],':g','linewidth',2);
% plot([-rotatedCoeffP(1,3,I) rotatedCoeffP(1,3,I)],[-rotatedCoeffP(3,3,I) rotatedCoeffP(3,3,I)],':b','linewidth',2);
hold off
axis equal
set(gca,'xlim',[-axLimit axLimit],'ylim',[-axLimit axLimit],'FontUnits','points','fontsize',7,'FontName','Arial')
xlabel('\bfE [\mum/s]');ylabel('\bfZ  [\mum/s]');

axes('units','normalized','position',[.7 .3 .3 .3],'FontUnits','points','fontsize',8,'FontName','Arial')
plot(data(:,2),data(:,3),'color',[.7 .7 .7]);
hold on
plot([-axLimit axLimit],(coeff(3,1)/coeff(2,1))*[-axLimit axLimit],'-r','linewidth',2);
plot([-axLimit axLimit],(coeff(3,2)/coeff(2,2))*[-axLimit axLimit],'--g','linewidth',2);
plot([-axLimit axLimit],(coeff(3,3)/coeff(2,3))*[-axLimit axLimit],':b','linewidth',2);
% % Rotated eigenvectors
% plot([-rotatedCoeffV(2,1,I) rotatedCoeffV(2,1,I)],[-rotatedCoeffV(3,1,I) rotatedCoeffV(3,1,I)],'--r','linewidth',1);
% plot([-rotatedCoeffV(2,2,I) rotatedCoeffV(2,2,I)],[-rotatedCoeffV(3,2,I) rotatedCoeffV(3,2,I)],'--g','linewidth',1);
% %     plot([-rotatedCoeff(2,3,I) rotatedCoeff(2,3,I)],[-rotatedCoeff(3,3,I) rotatedCoeff(3,3,I)],'--b','linewidth',1);
% plot([-rotatedCoeffP(2,1,I) rotatedCoeffP(2,1,I)],[-rotatedCoeffP(3,1,I) rotatedCoeffP(3,1,I)],':r','linewidth',2);
% plot([-rotatedCoeffP(2,2,I) rotatedCoeffP(2,2,I)],[-rotatedCoeffP(3,2,I) rotatedCoeffP(3,2,I)],':g','linewidth',2);
% plot([-rotatedCoeffP(2,3,I) rotatedCoeffP(2,3,I)],[-rotatedCoeffP(3,3,I) rotatedCoeffP(3,3,I)],':b','linewidth',2);
hold off
axis equal
set(gca,'xlim',[-axLimit axLimit],'ylim',[-axLimit axLimit],'FontUnits','points','fontsize',7,'FontName','Arial')
xlabel('\bfN [\mum/s]');ylabel('\bfZ  [\mum/s]');

end

% % Figure with scaled eigenvectors ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% figure('Name',['Filter ' num2str(bandPassFiltersTemp) 'Hz'])
% vectAmplifier = 20;                                                         % Scale factor to be applied to the explained variance of the eigenvectors for plotting purpouses
% counter = 1;
% for I = 1:size(fileNamesBlock,1)
%     dataBlockNoResp{I} = dataBlockNoResp{I}*scaleFactor;
%     xComp1 = vectAmplifier*scaleFactor*sqrt(latent(1,I))*coeff(1,1,I);
%     yComp1 = vectAmplifier*scaleFactor*sqrt(latent(1,I))*coeff(2,1,I);
%     zComp1 = vectAmplifier*scaleFactor*sqrt(latent(1,I))*coeff(3,1,I);
%     xComp2 = vectAmplifier*scaleFactor*sqrt(latent(2,I))*coeff(1,2,I);
%     yComp2 = vectAmplifier*scaleFactor*sqrt(latent(2,I))*coeff(2,2,I);
%     zComp2 = vectAmplifier*scaleFactor*sqrt(latent(2,I))*coeff(3,2,I);
%     xComp3 = vectAmplifier*scaleFactor*sqrt(latent(3,I))*coeff(1,3,I);
%     yComp3 = vectAmplifier*scaleFactor*sqrt(latent(3,I))*coeff(2,3,I);
%     zComp3 = vectAmplifier*scaleFactor*sqrt(latent(3,I))*coeff(3,3,I);
%     %     axes('units','normalized','position',[.1+(I-1)*axSize .3 axSize axSize],'FontUnits','points','fontsize',8,'FontName','Arial')
%     subplot(3,5,counter)
%     plot(dataBlockNoResp{I}(:,1),dataBlockNoResp{I}(:,2),'color',[.7 .7 .7]);
%     hold on
%     hleg(1) = plot([-xComp1 xComp1],[-yComp1 yComp1],'-r','linewidth',2);
%     hleg(2) = plot([-xComp2 xComp2],[-yComp2 yComp2],'-g','linewidth',2);
%     hleg(3) = plot([-xComp3 xComp3],[-yComp3 yComp3],'-b','linewidth',2);
%     hold off
%     axis equal
%     set(gca,'xlim',[-axLimit axLimit],'ylim',[-axLimit axLimit],'FontUnits','points','fontsize',7,'FontName','Arial')
%     xlabel('\bfE [\mum/s]');ylabel('\bfN  [\mum/s]');
%     title(['\bfSTAGE ' num2str(I-1)])
%     legend(hleg,['Expl. Var: ' num2str(explained(1,I),'%2.1f') '%'],[num2str(explained(2,I),'%2.1f') '%'],[num2str(explained(3,I),'%2.1f') '%'])
%     subplot(3,5,counter+5)
%     plot(dataBlockNoResp{I}(:,1),dataBlockNoResp{I}(:,3),'color',[.7 .7 .7]);
%     hold on
%     plot([-xComp1 xComp1],[-zComp1 zComp1],'-r','linewidth',2);
%     plot([-xComp2 xComp2],[-zComp2 zComp2],'-g','linewidth',2);
%     plot([-xComp3 xComp3],[-zComp3 zComp3],'-b','linewidth',2);
%     hold off
%     axis equal
%     set(gca,'xlim',[-axLimit axLimit],'ylim',[-axLimit axLimit],'FontUnits','points','fontsize',7,'FontName','Arial')
%     xlabel('\bfE [\mum/s]');ylabel('\bfZ  [\mum/s]');
%     subplot(3,5,counter+10)
%     plot(dataBlockNoResp{I}(:,2),dataBlockNoResp{I}(:,3),'color',[.7 .7 .7]);
%     hold on
%     plot([-yComp1 yComp1],[-zComp1 zComp1],'-r','linewidth',2);
%     plot([-yComp2 yComp2],[-zComp2 zComp2],'-g','linewidth',2);
%     plot([-yComp3 yComp3],[-zComp3 zComp3],'-b','linewidth',2);
%     hold off
%     axis equal
%     set(gca,'xlim',[-axLimit axLimit],'ylim',[-axLimit axLimit],'FontUnits','points','fontsize',7,'FontName','Arial')
%     xlabel('\bfN [\mum/s]');ylabel('\bfZ  [\mum/s]');
%     counter = counter +1;
% end

