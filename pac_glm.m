% pac_glm() -  calculate phase-amplitude coupling (PAC) using the
%     general linear model (GLM) method (see Penny, 2008)
%
% Usage:
%     >> pac = pac_glm(lo, hi, f_lo, f_hi, fs);
%
% Inputs:
%     lo          = voltage time series containing the low-frequency-band
%                   oscillation
%     hi          = voltage time series containing the high-frequency-band
%                   oscillation
%     f_lo        = cutoff frequencies of low-frequency band (Hz)
%     f_hi        = cutoff frequencies of high-frequency band (Hz)
%     fs          = sampling rate (Hz)
%
% Outputs:
%     pac         = phase-amplitude coupling value
%
% Example:
%     >> t = 0:.001:10; % Define time array
%     >> lo = sin(t * 2 * pi * 6); % Create low frequency carrier
%     >> hi = sin(t * 2 * pi * 100); % Create modulated oscillation
%     >> hi(angle(hilbert(lo)) > -pi*.5) = 0; % Clip to 1/4 of cycle
%     >> pac_glm(lo, hi, [4,8], [80,150], 1000) % Calculate PAC
%     ans =
%         0.6706
%
% See also: comodulogram(), pa_series(), pa_dist()

% Author: Scott Cole (Voytek lab) 2015

function pac = pac_glm(lo, hi, f_lo, f_hi, fs)


    y = hi'; % assumes hi is row vector
    X = [cos(lo); sin(lo)]'; % assumes low is row vector
    [b, bint, resid] = regress(y, X);

    % Calculate PAC from GLM residuals
    pac = 1 - (resid'*resid)/((hi - mean(hi))*(hi - mean(hi))');
end