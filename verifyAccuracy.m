% This script looks at the data in SAVE/trainingScores.mat and sees
% how well the user performed.

close all, clear all

d = load('SAVE/trainingScores.mat');
% d = load('SAVE/trainingScores-JH.mat'); % Backup 2014-09-22


old = d.oldScores;

% For some reason old(1) has an empty realDV value
disp('Removing first oldScores entry, since realDV was empty there')
old = old(2:end);


realNT = cat(1,old.realNT);
guessedNT = cat(1,old.guessedNT);

realDV = cat(1,old.realDV);
guessedDV = cat(1,old.guessedDV);

figure
plot([realNT,realNT]',[realNT,guessedNT]','r-', ...
     realNT,guessedNT,'k.', ...
     'markersize',30,'linewidth',2)
xlabel('Real NT','fontsize',24)
ylabel('Estimated NT','fontsize',24)
set(gca,'fontsize',20)
axis([0 1 0 1])
box off
saveas(gcf,'FIGS/Synthetic-data-NT.pdf','pdf')

figure
plot([realDV,realDV]',[realDV,guessedDV]', 'r-', ...
     realDV,guessedDV,'k.', ...
     'markersize',30,'linewidth',2)
xlabel('Real DV','fontsize',24)
ylabel('Estimated DV','fontsize',24)
set(gca,'fontsize',20)
axis([0 1 0 1])
box off
saveas(gcf,'FIGS/Synthetic-data-DV.pdf','pdf')


