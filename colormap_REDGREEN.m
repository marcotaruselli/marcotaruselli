%%%%%%%%%%%%
hex = ['#FF0000'
'#FF1100'
'#FF2300'
'#FF3400'
'#FF4600'
'#FF5700'
'#FF6900'
'#FF7B00'
'#FF8C00'
'#FF9E00'
'#FFAF00'
'#FFC100'
'#FFD300'
'#FFE400'
'#FFF600'
'#F7FF00'
'#E5FF00'
'#D4FF00'
'#C2FF00'
'#B0FF00'
'#9FFF00'
'#8DFF00'
'#7CFF00'
'#6AFF00'
'#58FF00'
'#47FF00'
'#35FF00'
'#24FF00'
'#12FF00'
'#00FF00'];
vec = linspace(100,0,size(hex,1))';
raw = sscanf(hex','#%2x%2x%2x',[3,size(hex,1)]).' / 255;
N = 128;
%N = size(get(gcf,'colormap'),1) % size of the current colormap
map = interp1(vec,raw,linspace(100,0,N),'pchip');