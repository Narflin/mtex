function S2G = plotS2Grid(varargin)

% extract options
bounds = getPolarRange(varargin{:});

% set up polar angles
theta = S1Grid(linspace(bounds.VR{1:2},bounds.points(2)),bounds.FR{1:2});

% set up azimuth angles
steps = (bounds.VR{4}-bounds.VR{3}) / bounds.points(1);
rho = repmat(...
  S1Grid(bounds.VR{3} + steps*(0:bounds.points(1)),bounds.FR{3:4}),...
  1,bounds.points(2));

S2G = S2Grid(theta,rho);

S2G = S2G.set('plot',true,'resolution',steps);

%S2G = set_option(S2G,extract_option(varargin,{'INDEXED','PLOT','north','south','antipodal','lower','upper'}));

end
