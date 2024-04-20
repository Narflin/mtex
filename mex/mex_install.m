function mex_install(mtexpath,varargin)
% compiles all mex files for use with MTEX
%
% You need a mex Compiler for example MinGW64 for Windows 
%         --> Home/AddOns/Get Add-Ons ...
%

if nargin == 0, mtexpath = mtex_path;end

places = {'geometry/@S1Grid/private/S1Grid_',...
  'geometry/@S2Grid/private/S2Grid_',...
  'geometry/@SO3Grid/private/SO3Grid_',...
  'extern/insidepoly/',...
  'extern/jcvoronoi/',...
  'extern/libDirectional/num',...
  'SO3Fun/@SO3FunHarmonic/private/adjoint',...
  'SO3Fun/@SO3FunHarmonic/private/representationbased',...
  'tools/graph_tools/EulerCyclesC'};
  
% TODO: Check for mex-Compiler

mexPath = [mtexpath filesep 'mex'];

% compile all the files
for p = 1:length(places)
  files = dir([fullfile(mtexpath,places{p}),'*.c*']);
  for f = 1:length(files)
    if ~files(f).isdir
      cFile = fullfile(files(f).folder,files(f).name);

      [~,fName,~] = fileparts(files(f).name);
      mexFile = fullfile(mexPath,[fName '.' mexext]);
      mexFileD = dir(mexFile);

      if isempty(mexFileD) || check_option(varargin,'force') || ...
          mexFileD.datenum < files(f).datenum
        disp(['... compiling ',files(f).name]);

        compFile = fullfile(files(f).folder,'compile.m');
        try
          if exist(compFile,"file")
            run(compFile)
            movefile(fullfile(files(f).folder,[fName '.' mexext]),mexFile,'f')
          else
            mex('-R2018a','-outdir',mexPath,cFile);
          end
        catch
          if ~contains(lasterr,'is not a MEX file.'), disp(lasterr); end %#ok<LERR>
        end
      else
        disp(['... skipping ',files(f).name]);
      end
    end
  end
end
end
