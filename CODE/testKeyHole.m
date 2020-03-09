function [inTail,distToPredict,whichT]=testKeyHole(branchIn,childInTail,circRadius)
%function [inTail,distToPredict,whichT]=testKeyHole(branchIn,childInTail,circRadius)
%
%--------------------------------------------------------------------------
% testKeyHole   A keyHole is generated and tested for points to be inside or outside
%     The tail is generated by a circle and 60 degree wedge
%           * Two points in a branch, circular + wedge as in a keyhole, tailDist = dist between nodes
%           * A single point in the branch and more nodes is prevented from the call to the function
%     Main output is to determine if childInTail lies or not in the testKeyHole region of a point/branch
%
%       INPUT
%         branchIn:             the  point/points to be tested
%         childInTail:          is used to test if a point coincides with the area generated
%         circRadius:           radius of the circular region around the point or edge of branch
%
%       OUTPUT
%         inTail:               true if is in tail;
%         distToPredict:        distance
%         whichT:               tail
%          
%--------------------------------------------------------------------------
%
%     Copyright (C) 2012  Constantino Carlos Reyes-Aldasoro
%
%     This file is part of the PhagoSight package.
%
%     The PhagoSight package is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, version 3 of the License.
%
%     The PhagoSight package is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with the PhagoSight package.  If not, see <http://www.gnu.org/licenses/>.
%
%--------------------------------------------------------------------------
%
% This m-file is part of the PhagoSight package used to analyse fluorescent phagocytes
% as observed through confocal or multiphoton microscopes.  For a comprehensive 
% user manual, please visit:
%
%           http://www.phagosight.org.uk
%
% Please feel welcome to use, adapt or modify the files. If you can improve
% the performance of any other algorithm please contact us so that we can
% update the package accordingly.
%
%--------------------------------------------------------------------------
%
% The authors shall not be liable for any errors or responsibility for the 
% accuracy, completeness, or usefulness of any information, or method in the content, or for any 
% actions taken in reliance thereon.
%
%--------------------------------------------------------------------------

if nargin < 2                   ;     help testKeyHole;           return;  end;

%------ the wedge will be 3x the distance of the predicted landing and approximately 60 degrees wide
wedgeLength=3;
wedgeWidth=1.04;

%------ structure of the branch is [x y z ....] so
%------ rows defines number of nodes
[numChild]                              = size(childInTail,1);

%------ The line that intersects the two points in the branch will predict where the next point will fall
%------ it is important to calculate the distance between these points and the angle it is following
%------ if branchIn has 2 points or more, it has a prediction to where the point may be moving, otherwise
%------ only use a circular prediction of small size, if 2 points are the same, then only circle applies

% %----- the predicted point is calculated
% newPoint=branchIn(1,:)-diffBet_1_end;
%----- from  the prediction 2 regions are calculated
%----- 1    a circle around the starting point                  radius  = dist
%----- 2    a 60 lobe towards the prediction                    lobe    = 3 dist
%----------- the distance from the edge of the branch (starting point) to all nodes to be tested (squared)


%------ this is independent of the branch received: top node in brachIn is the parent node to be tested
startPointRepeated                      = repmat(branchIn(1,:),numChild,1);
%------ distance from the start point of the branch to all the children
diffToStart                             = childInTail-startPointRepeated;
distToStart                             = sqrt(sum((diffToStart).^2,2));
%------ angle from the last point of the branch to all the children
angleToStart                            = atan2(diffToStart(:,2),diffToStart(:,1) );


%------ there are always 2 nodes in the brach, there should not be a case of rows==1 or rows>2
%if rows==2
%----- obtain distances, between first and last, if more, get the highest value
%----- the slope will be between first and last point, it should average 'blips'
diffBet_1_2                             = (diff(branchIn([1 2],:)));
distBet_1_2                             = sqrt(sum(diffBet_1_2.^2,2));
if distBet_1_2==0
    % CASE 1
    inTail                              = (distToStart<=(ceil(1.0*circRadius)));
    distToPredict                       = distToStart;
    whichT                              = 1*(inTail==1);
else
    %---- prepare number for a predicted Landing, angles
    slope_1_2                           = atan2(-diffBet_1_2(2),-diffBet_1_2(1));
    relAngle_1_2                        = angleToStart-slope_1_2;
    relAngle_1_2                        = relAngle_1_2-sign(relAngle_1_2).*(2*pi*(abs(relAngle_1_2)>pi));
    %---- calculate predicted landing and distances to possible children
    predictedLanding(1,:)               = branchIn(1,:)+distBet_1_2*[cos(slope_1_2) sin(slope_1_2) 0];
    distToPredict                       = sqrt(sum( (childInTail-repmat(predictedLanding(1,:),numChild,1)).^2,2));
    
    % this line guarantees that the distance will be at least *1* pixel
    distBet_1_2                         = ceil(distBet_1_2);
    % CASE 2 Wide wedge from start point
    inTail2                             = (abs(relAngle_1_2)<wedgeWidth)&((distToPredict)<(wedgeLength*distBet_1_2));
    %inTail2                             = (abs(relAngle_1_2)<wedgeWidth)&((distToStart)<(wedgeLength*distBet_1_2));
    % CASE 3 CIRCLE AROUND START POINT
    inTail1                             = distToStart<=(7+ceil(0.5*distBet_1_2));
    % inTail will combine the two areas of the keyHole
    inTail                              = inTail1|inTail2;
    %----- whichT will define which area of probability has captured the child RBC if any CASE 2 should take priority before CASE 3
    whichT                              = 2*(inTail2==1)+3*((inTail2==0).*(inTail1==1));
    if isempty(inTail)
        inTail=0; whichT=0;
    end
    distToPredict                       = (distToPredict+distToStart)/2;

end
