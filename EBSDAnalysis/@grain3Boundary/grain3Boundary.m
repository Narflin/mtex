classdef grain3Boundary < phaseList & dynProp

  properties  % with as many rows as data
    id = []
    poly                  % cell array with all faces
    grainId = zeros(0,2)  % id's of the neighboring grains to a face
                          % (faceNormals direction from grain#1 to grain#2)
    ebsdId = zeros(0,2)  % id's of the neighboring ebsd data to a face
    misrotation = rotation % misrotations
  end
  
  properties
    idV      % ids of the used vertices ?
    allV     % vertices
  end

  properties (Dependent)
    V
    misorientation
  end

  methods

    function gB = grain3Boundary(V, poly, ebsdInd, grainId, phaseId, mori, CSList, phaseMap, ebsdId, varargin)
      %
      % Input
      %  V       - @vector3d list of vertices
      %  poly    - list of boundary segments
      %  ebsdInd - [Id1,Id2] list of adjacent EBSD index for each segment
      %  grainId - [Id1,Id2] list of adjacent grainIds for each segment
      %  phaseId - list of adjacent phaseIds for each segment     
      %  mori    - misorientation at each segment
      %  CSList  - list of phases
      %  phaseMap - 
      %  ebsdInd - [Id1,Id2] list of adjacent EBSD Ids for each segment
      
      % ensure V is vector3d
      V = reshape(vector3d(V),[],1);
      
      gB.allV = V;
      gB.idV = (1:length(V))';
      gB.poly = poly;
      gB.id = (1:length(poly))';
      gB.grainId = grainId;
      gB.misrotation = mori;

      gB.ebsdId = ebsdInd;
      if nargin == 9 % store ebsd_id instead of index
        gB.ebsdId(ebsdInd>0) = ebsdId(ebsdInd(ebsdInd>0));
      end

      gB.phaseId = zeros(size(ebsdInd));
      gB.phaseId(ebsdInd>0) = phaseId(ebsdInd(ebsdInd>0));

      gB.CSList = CSList;
      gB.phaseMap = phaseMap;
      
    end

    function V = get.V(gB3)
      V = gB3.allV(gB3.idV);
    end

    function gB3 = set.V(gB3,V)
      gB3.allV(gB3.idV) = V;
    end

    function mori = get.misorientation(gB3)
            
      mori = orientation(gB3.misrotation,gB3.CS{:});
      mori.antipodal = equal(checkSinglePhase(gB3),2);
      
      % set not indexed orientations to nan
      if ~all(gB3.isIndexed), mori(~gB3.isIndexed) = NaN; end
      
    end


    function out = hasPhaseId(gB,phaseId,phaseId2)
      if isempty(phaseId), out = false(size(gB)); return; end
      
      if nargin == 2
        out = any(gB.phaseId == phaseId,2);

        % not indexed phase should include outer border as well
        if phaseId > 0 && ischar(gB.CSList{phaseId}), out = out | ...
          any(gB.phaseId == 0,2); end
        
      elseif isempty(phaseId2)
        out = false(size(gB));
      elseif phaseId == phaseId2
        out = all(gB.phaseId == phaseId,2);
      else
        out = gB.hasPhaseId(phaseId) & gB.hasPhaseId(phaseId2);
      end 
    end

  end

end