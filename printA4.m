function printA4(figName)

%set(gcf,'PaperPositionMode','auto')  
%set(gcf,'PaperType','A4')  

print(figName, ...
      '-depsc', ...
      '-r300')

system(sprintf('ps2pdf -dEPSCrop %s', figName))