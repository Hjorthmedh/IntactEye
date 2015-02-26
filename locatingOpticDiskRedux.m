clear all, close all

% This uses polar coordinates

expList = {'D5.6', 'Ret22.2', 'Ret22.3', 'Ret22.6', 'Ret22.9', 'Ret32.2'};
expPath = '/Users/hjorth/DATA/ReberRetina';

ES = EyeSphere([],[],[]);

for i = 1:numel(expList)
  
  fNameRS = sprintf('%s/%s/r.mat', expPath, expList{i});
  dRS = load(fNameRS);
  ODcentreRS(i,:) = mean(dRS.Sss.OD,1);
  
  fNameIEmask = sprintf('SAVE/OD/*%s*-save.mat', expList{i}(2:end));
  dName = dir(fNameIEmask);
  
  try
    assert(numel(dName) == 1);
  catch e
    getReport(e)
    keyboard
  end
  
  fNameIE = sprintf('SAVE/OD/%s', dName(1).name);
  dIE = load(fNameIE);
  
  % In OD directory the optic disc is marked as an injection, use that data
  inj = dIE.data.topView_injection;
  r = dIE.data.topView_radius;
  
  assert(numel(inj) == 3)
  
  [rSphere,theta,phi] = ES.getPolarCoordinates(inj(1)/r(1),inj(2)/r(2),inj(3)/r(3));
  
  ODcentreIE(i,:) = [theta,phi];
  
end

figure

v = linspace(0,2*pi,100);
p2 = polar(v,5*ones(1,100),'y-');
hold on

ODcentreIE(:,1) = pi/2 + ODcentreIE(:,1);

ODcentreIE(:,1) = pi - ODcentreIE(:,1);

p = polar([ODcentreIE(:,2), ODcentreRS(:,2)]', [ODcentreIE(:,1) ODcentreRS(:,1)]','-')
mIE = polar(ODcentreIE(:,2),ODcentreIE(:,1),'k.');
mRS = polar(ODcentreRS(:,2),ODcentreRS(:,1),'kv');

set(mIE,'markersize',20)
set(mRS,'markersize',6)

delete(p2)
legend(p,expList)


axis equal
set(gca,'fontsize',15)

saveas(gcf,'FIGS/optic-disk-comparison-RS-IE.pdf','pdf')