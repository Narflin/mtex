function val = evalfft(SO3F,varargin)
% Do fft for the fourier coefficients of SO3F and give the grid if there
% are no evaluation points given.
%
% Syntax
%   val = evalfft(SO3F)
%
% Input
%  SO3F - @SO3FunHarmonic
%
% Output
%  val.nodes  - @rotation : grid on SO3F 
%  val.values - values at this grid points
%
% Example
%   SO3F = SO3FunHarmonic(SO3Fun.dubna);
%   v = SO3F.evalfft;
%   v.values - SO3F.eval(v.nodes)
% 

N = SO3F.bandwidth;

% get number of grid points
H = ceil(get_option(varargin,'GridPointNum',2*N+1)/2-1);


% % if there are no @rotation given, do dft
% if ~isempty(varargin) && isa(varargin{1},'rotation')
%   rot = varargin{1};
%   dft = false;
% else
%   dft = true;
% end
% 
% % get interpolation method
% method = get_flag(varargin,{'nearest','trilinear'},'trilinear');
% 
% % give gridconstant h
% h = pi/(H+1);


% 1) calculate FFT of SO3F

% if SO3F is real valued we have (*) and (**) for the Fourier coefficients
% we will use this to speed up computation
if SO3F.isReal

  % create ghat -> k x j x l
  % with  k = -N:N
  %       j = -N:N    -> use ghat(k,-j,l) = (-1)^(k+l) * ghat(k,-j,l)   (*)
  %       l =  0:N    -> use ghat(-k,-j,-l) = conj(ghat(k,j,l))        (**)
  % flags: 2^0 -> use L_2-normalized Wigner-D functions
  %        2^2 -> fhat are the fourier coefficients of a real valued function
  %        2^4 -> use right and left symmetry
  flags = 2^0+2^2+2^4;
  sym = [min(SO3F.SRight.multiplicityPerpZ,2),SO3F.SRight.multiplicityZ,...
         min(SO3F.SLeft.multiplicityPerpZ,2),SO3F.SLeft.multiplicityZ];
  ghat = representationbased_coefficient_transform(N,SO3F.fhat,flags,sym);

  % correct ghat by (-1)^(k-l)
  z = zeros(2*N+1,2*N+1,N+1)+(-N:N)'-reshape(0:N,1,1,[]);
  ghat = ghat.*(1i).^z;

else

  % flags: 2^0 -> use L_2-normalized Wigner-D functions
  %        2^4 -> use right and left symmetry
  flags = 2^0+2^4;
  sym = [min(SO3F.SRight.multiplicityPerpZ,2),SO3F.SRight.multiplicityZ,...
         min(SO3F.SLeft.multiplicityPerpZ,2),SO3F.SLeft.multiplicityZ];
  ghat = representationbased_coefficient_transform(N,SO3F.fhat,flags,sym);

  % correct ghat by (-1)^(k-l)
  z = zeros(2*N+1,2*N+1,2*N+1)+(-N:N)'-reshape(-N:N,1,1,[]);
  ghat = ghat.*(1i).^z;

end


% fft
f = fftn(ghat,[2*H+2,2*H+2,2*H+2]);

f = f(:,1:H+2,:);                          % because beta is only in [0,pi]

if SO3F.isReal
  % need to shift summation of fft from [-N:N] to [0:2N]
  z = (0:H+1)+(0:2*H+1)';
  f = 2*real(exp(1i*pi*N/(H+1)*z).*f);     % shift summation & use (**)
else
  % need to shift summation of fft from [-N:N] to [0:2N]
  z = (0:H+1)+(0:2*H+1)'+reshape(0:2*H+1,1,1,[]);
  f = exp(1i*pi*N/(H+1)*z).*f;
end


% if dft
  grid(:,[3,2,1]) = combvec(0:2*H+1,0:2*H+1,0:2*H+1)'*pi/(H+1);
  grid = grid(grid(:,2)<=pi,:);
  grid = orientation.byEuler(grid,'nfft',SO3F.CS,SO3F.SS);
  val.nodes = reshape(grid,size(f));
  val.values = f;
%   return
% end





% evaluate harmonic SO3function in rotations by using fft
%
% Therefore the rotations are given by euler angles 'ZYZ'. This euler
% angles describe SO(3) as [0,2pi]x[0,pi]x[0,2pi] with some special isues.
% There is a equidistant grid used for fft. At least the evaluation at the
% desired rotations is done by interpolation between the grid points.
%
% dft with interpolation
%
% Syntax
%   val = evalfft(SO3F,rot,'trilinear','GridPointNum',127)
%
% Input
%   SO3F - @SO3FunHarmonic
%   rot  - @rotation
%
% Output
%   val - approximation of SO3F at rotations
%
% Options
%   'GridPointNum' - H as number of grid points in [0,2*pi):
%                           grid points 2*pi*k/H, k=0,...,H-1 and
%                           gridconstant (2*pi)/H
%   'nearest'      - use function value of nearest grid point
%   'trilinear'    - trilinear interpolation by the neighbor points
%
%





% % 2) evaluate SO3F in rot
% 
% sz = size(rot);
% rot = rot(:);
% M = length(rot);
% 
% % gridconst h and 2H+2 x H+2 x 2H+2 grid points in [0,2pi)x[0,pi]x[0,2pi)
% abg = Euler(rot,'nfft');
% abg = mod(abg/h,2*H+2);
% 
% % interpolation
% if strcmpi(method,'nearest')
% 
%   % basic := index of nearest grid point of rot
%   basic = round(abg);
%   ind = basic(:,1)*(2*H+2)*(H+2)+basic(:,2)*(2*H+2)+basic(:,3)+1;
%   val = f(ind);
% 
% elseif strcmpi(method,'trilinear')
%   
%   % basic := index of next rounded down grid point of rot
%   basic = floor(abg);
%   % if beta = pi : we change basic point, to avoid domain error later
%   basic((basic(:,2)==H+1),2) = H;
% 
%   % get the indices of the other grid points around rot
%   X = [0,0,0,0,1,1,1,1;0,0,1,1,0,0,1,1;0,1,0,1,0,1,0,1]';
%   gp = reshape(X,1,8,3)+reshape(basic,M,1,3);
%   gp(gp==2*H+2) = 0;
% 
%   % get the indices of this grid points for f(:) from FFT
%   ind = gp(:,:,1)*(2*H+2)*(H+2)+gp(:,:,2)*(2*H+2)+gp(:,:,3)+1;
% 
%   % transform coordinates in h^3 cube with gp as edges to [0,1]^3
%   pkt = abg-basic;
%   % calculate therefore a weightmatrix
%   w = prod(abs(reshape(X==0,1,8,3)-reshape(pkt,M,1,3)),3);
% 
%   % get evaluation in rot
%   val = sum(w.*f(ind),2);
% 
% end
% 
% val = reshape(val,sz);
% 
% end