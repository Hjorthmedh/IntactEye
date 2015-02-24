% This script looks at the data in SAVE/trainingScores.mat and sees
% how well the user performed.

close all, clear all

% d = load('SAVE/trainingScores.mat');
dJH = load('SAVE/trainingScores-JH.mat'); % Backup 2014-09-22
dEC = load('SAVE/trainingScores-EC.mat'); 
dES = load('SAVE/trainingScores-ES.mat'); 

JH = dJH.oldScores;
EC = dEC.oldScores;
ES = dES.oldScores;

% For some reason old(1) has an empty realDV value
disp('Removing first oldScores entry, since realDV was empty there')
JH = JH(2:end);

% Ellese had missed to move the sphere to overlay the image, remove those
r = cat(2,EC.guessedRadius);
idx = find(r(3,:) ~= 100)
EC = EC(idx);

% Same bug in Eliese's data
ES = ES(2:end);

realNT{1} = cat(1,JH.realNT);
guessedNT{1} = cat(1,JH.guessedNT);
realNT{2} = cat(1,EC.realNT);
guessedNT{2} = cat(1,EC.guessedNT);
realNT{3} = cat(1,ES.realNT);
guessedNT{3} = cat(1,ES.guessedNT);


realDV{1} = cat(1,JH.realDV);
guessedDV{1} = cat(1,JH.guessedDV);
realDV{2} = cat(1,EC.realDV);
guessedDV{2} = cat(1,EC.guessedDV);
realDV{3} = cat(1,ES.realDV);
guessedDV{3} = cat(1,ES.guessedDV);

colours = [27,158,119;
           217,95,2;
           117,112,179]/255;

figure, hold on
for i = 1:numel(realNT)
  plot([realNT{i},realNT{i}]',[realNT{i},guessedNT{i}]','k-', ...
       'linewidth', 2);
  pNT(i) = plot(realNT{i},guessedNT{i},'.', ...
                'color', colours(i,:), ...
                'markersize',30,'linewidth',2)
end
xlabel('Synthetic NT','fontsize',24)
ylabel('Estimated NT','fontsize',24)
set(gca,'fontsize',20)
axis equal
axis([0 1 0 1])
set(gca,'xtick',0:0.2:1)
set(gca,'ytick',0:0.2:1)

box off
legend(pNT,'JH','EC','ES','location','southeast')

saveas(gcf,'FIGS/Synthetic-data-NT.pdf','pdf')

figure, hold on
for i = 1:numel(realDV)
  plot([realDV{i},realDV{i}]',[realDV{i},guessedDV{i}]', 'k-', ...
       'linewidth', 2);
  pDV(i) = plot(realDV{i},guessedDV{i},'.', ...
                'color',colours(i,:), ...
                'markersize',30,'linewidth',2)
end
xlabel('Synthetic DV','fontsize',24)
ylabel('Estimated DV','fontsize',24)
set(gca,'fontsize',20)
axis equal
axis([0 1 0 1])
set(gca,'xtick',0:0.2:1)
set(gca,'ytick',0:0.2:1)

box off
% legend(pDV,'JH','EC','ES','location','southeast')

saveas(gcf,'FIGS/Synthetic-data-DV.pdf','pdf')


