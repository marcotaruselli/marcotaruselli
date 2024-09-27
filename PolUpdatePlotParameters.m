function PolUpdatePlotParameters(fs)

global mainPolFig
global polUpdatePlotFig
global polPlotParameters

axesTypeString = get(findobj(polUpdatePlotFig,'tag','axes_type'),'string');
axesTypeValue = get(findobj(polUpdatePlotFig,'tag','axes_type'),'value');
polPlotParameters.axesType = axesTypeString{axesTypeValue};
%
freqAxisString = get(findobj(polUpdatePlotFig,'tag','frequency_axis'),'string');
freqAxisValue = get(findobj(polUpdatePlotFig,'tag','frequency_axis'),'value');
polPlotParameters.freqAxis = freqAxisString{freqAxisValue};
%
freqLimitsTmp = get(findobj(polUpdatePlotFig,'tag','frequency_limits'),'string');
if strcmp(freqLimitsTmp,'auto')
    polPlotParameters.freqLim = [1/(str2double(get(findobj(mainPolFig,'tag','time_window'),'string'))/10) fs/2];
else
    freqLimits = [str2double(freqLimitsTmp(1:strfind(freqLimitsTmp,'-')-1)) str2double(freqLimitsTmp(strfind(freqLimitsTmp,'-')+1:end))];
    if freqLimits(1)<0 || freqLimits(2)>fs/2 || freqLimits(1)>freqLimits(2) || any(isnan(freqLimits))
        errordlg('Please correct frequency limits','Input parameter Error',opts);
        return
    elseif freqLimits(1)==0 && strcmp(freqAxis,'Logarithmic')
        errordlg('Lower limit of logarithmic frequency axis cannot be 0','Input parameter Error',opts);
        return
    end
    polPlotParameters.freqLim = freqLimits;
end
%
polPlotParameters.freqTicks = 'auto';
%
colormapString = get(findobj(polUpdatePlotFig,'tag','colormap_name'),'string');
colormapValue = get(findobj(polUpdatePlotFig,'tag','colormap_name'),'value');
polPlotParameters.colormap = colormapString{colormapValue};
%
polPlotParameters.colormapRange = get(findobj(polUpdatePlotFig,'tag','colormap_range'),'string');
%
HVSRAngularRuleString = get(findobj(polUpdatePlotFig,'tag','HVSR_angular_rule'),'string');
HVSRAngularRuleValue = get(findobj(polUpdatePlotFig,'tag','HVSR_angular_rule'),'value');
polPlotParameters.HVSRAngularRule = HVSRAngularRuleString{HVSRAngularRuleValue};

delete(polUpdatePlotFig);
tempAxes = findobj(mainPolFig,'type','axes');
for I = 1:size(tempAxes,1)
    if not(strcmpi(get(tempAxes(I),'tag'),'comp_x')) && not(strcmpi(get(tempAxes(I),'tag'),'comp_y')) && not(strcmpi(get(tempAxes(I),'tag'),'comp_z'))
     delete(tempAxes(I));
    end
end
delete(findobj(mainPolFig,'type','polaraxes'))
drawnow;
%
polAlgorithmString = get(findobj(mainPolFig,'tag','polarization_algorithm'),'string');
polAlgorithmValue = get(findobj(mainPolFig,'tag','polarization_algorithm'),'value');
polAlgorithm = polAlgorithmString{polAlgorithmValue};
%
switch polAlgorithm
    case('HV rotate')
        PolHVRotate(1);
    case('H rotate')
        PolHRotate(1);
    case('SVD spectral matrix')
        PolSVDSpectralMatrix(1);
end
