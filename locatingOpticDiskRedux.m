clear all, close all

% This uses polar coordinates

expList = {'D5.6', 'Ret22.2', 'Ret22.3', 'Ret22.6', 'Ret22.9', 'Ret32.2'};
expPath = '/Users/hjorth/DATA/ReberRetina';

expColour = [166,206,227
             31,120,180
             178,223,138
             51,160,44
             251,154,153
             227,26,28]/255;


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
p2 = polar(v,3*ones(1,100),'y-');
hold on

spokesV = [0 180; 30 210; 60 240; 90 270; 120 300; 150 330]'*pi/180;
spokesV2 = linspace(0,2*pi,100);

plot(3*cos(spokesV),3*sin(spokesV),'-','color',0.6*[1 1 1])
plot(1*cos(spokesV2),1*sin(spokesV2),'-','color',0.6*[1 1 1])
plot(2*cos(spokesV2),2*sin(spokesV2),'-','color',0.6*[1 1 1])
plot(3*cos(spokesV2),3*sin(spokesV2),'-','color',0.6*[1 1 1])

% Plot the circles and lines in another colour, since I did not
% find a way to directly change the colours

ODcentreIE(:,1) = pi/2 + ODcentreIE(:,1);

ODcentreIE(:,1) = pi - ODcentreIE(:,1);

for i = 1:numel(expList)
  p(i) = polar([ODcentreIE(i,2), ODcentreRS(i,2)]', [ODcentreIE(i,1) ODcentreRS(i,1)]');
  set(p(i),'color',expColour(i,:),'linewidth',2)
  mIE = polar(ODcentreIE(i,2),ODcentreIE(i,1),'.');
  set(mIE,'color',expColour(i,:));
  mRS = polar(ODcentreRS(i,2),ODcentreRS(i,1),'v');
  set(mRS,'color',expColour(i,:));
  set(mIE,'markersize',40)
  set(mRS,'markersize',12)

end
  

delete(p2)
legend(p,expList)


axis equal
set(gca,'fontsize',20)

th = findall(gcf,'Type','text');
for i = 1:length(th),
      set(th(i),'FontSize',18)
end

saveas(gcf,'FIGS/optic-disk-comparison-RS-IE.pdf','pdf')