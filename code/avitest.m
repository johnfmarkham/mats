fig=figure(147);
set(fig,'DoubleBuffer','on');
set(gca,'xlim',[-80 80],'ylim',[-80 80],...
 'nextplot','replace','Visible','off')
aviobj = avifile('example11.avi','compression','FFDS')
x = -pi:.5:pi;
radius = [0:length(x)];
for i=1:length(x)
h = patch(sin(x)*radius(i),cos(x)*radius(i),[abs(cos(x(i))) 0 0]);
set(h,'EraseMode','xor');
frame = getframe(gca);
aviobj = addframe(aviobj,frame);
end
aviobj = close(aviobj);