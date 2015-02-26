function plotFlatRepresentation(obj,injection,injectionArea,fig)
 
  disp('plotFlatRepresentation called')
  
  if(~exist('injection') | isempty(injection) | numel(injection) ~= 3)
    return
  end
  
  if(exist('fig'))
    if(fig == -1)
      % Use the current figure
    elseif(~isempty(fig))
      figure(fig)
    end
  else
    set(obj.fig,'currentaxes',obj.handlePolarAxis);
    cla
  end
  
  
  sphere = obj.topView;
  
  rimAngle = pi - sphere.rimAngle;

  nPoints = 100;
  v = linspace(0,2*pi,nPoints);

  polar(v,ones(size(v)),'k--')
  hold on
  polar(v,toRadius(rimAngle*ones(1,nPoints)),'b-');
  
  injPlotted = false;
  
  % Draw injection area if we have it
  
  if(exist('injectionArea') & ~isempty(injectionArea))
    xA = injectionArea(:,1);
    yA = injectionArea(:,2);
    zA = injectionArea(:,3);    
    
    rA = sqrt(sum(injectionArea.^2,2));
    thetaA = acos(zA./rA);
    phiA = atan2(yA,xA);
  
    p = polar(phiA,toRadius(thetaA),'r.');
    injPlotted = true;
  end
  
  
  % Now draw the injection centre
  
  x = [];
  y = [];
  z = [];
  
  if(exist('injection'))
    if(~isempty(injection))
      x = injection(1,:);
      y = injection(2,:);
      z = injection(3,:);
    end    
  else
    % Only draw injection if it is there
    if(~isempty(sphere.injection))
      x = sphere.injection(1,:);
      y = sphere.injection(2,:);
      z = sphere.injection(3,:);
    end
  end
  
  r = sqrt(sum(sphere.injection.^2,1));
  theta = acos(z./r);
  phi = atan2(y,x);
  
  if(~injPlotted)
    polar(phi,toRadius(theta),'r*')
  end
  
  function vR = toRadius(v)
   vR = (pi - v)./pi;
  end
  
  
  text(1.15,0,'N','fontsize',30)
  text(-1.15,0,'T','fontsize',30,'horizontalalignment','right')
  
  switch(sphere.side)
    case 'left'
      text(0,1.15,'V','fontsize',30,'horizontalalignment','center')
      text(0,-1.15,'D','fontsize',30,'horizontalalignment','center')

    case 'right'
      text(0,1.25,'D','fontsize',30,'horizontalalignment','center')
      text(0,-1.25,'V','fontsize',30,'horizontalalignment','center')
     
    otherwise
      fprintf('Unknown side: %s\n', sphere.side)
  end
  
end