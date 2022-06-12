%% TEST_PARTICLETRACK   Visualizes vector field of wind using particles
%  v3   Converts data structure to Tables
%  v2   Regenerates quivers that go out of range
%       Randomizes generation
%       Add "active" and "age" fields
%       Refactor code to remove for loops (use comma sep lists and deal function)

% This variant is based on v2 and changes data to tables from structures

close all

%% Parameters
speedfactor = 0.01;     % Speed of particles scaled with U & V.
recordmovie = false;    % Set to true to record AVI.
moviefilename = 'Y2Y_3';  % Name of movie to output.
iteratelimit = 100;     % Number of time steps to animate for shorter testing.
                        % Change to inf to iterate over all files.
regulargrid = false;
numquivers = 0;         % If set to zero, will be determined by grid

%% Load and process files

% This is a "dir" on the folders that contain the data files
d = dir(".." + filesep + ".." + filesep + "ECMWF_ED" + filesep + "U" + filesep + "*.tif");

% Build list of files and count them
files = (string({d.folder}) + filesep + string({d.name}));
numfiles = numel(files);
iteratelimit = min(iteratelimit,numfiles);

% Get map info
info = georasterinfo(files(1));
[LAT,LON] = geographicGrid(info.RasterReference);
gridsize = info.RasterSize;

%% Initialize figure

fig = figure;
[minlat,maxlat] = bounds(LAT(:));
[minlon,maxlon] = bounds(LON(:));
ax = worldmap([minlat,maxlat],[minlon,maxlon]);

land = shaperead('landareas.shp', 'UseGeoCoords', true);
geoshow(ax, land, 'FaceColor', [0.5 0.7 0.5])

lakes = shaperead('worldlakes.shp', 'UseGeoCoords', true);
geoshow(lakes, 'FaceColor', 'blue')

rivers = shaperead('worldrivers.shp', 'UseGeoCoords', true);
geoshow(rivers, 'Color', 'blue')

%% Read in U & V

timeidx = 1;
U = zeros(gridsize(1),gridsize(2),numfiles);
V = zeros(gridsize(1),gridsize(2),numfiles);
timestamp = cell(numfiles,1);
for filename = files
    timestring = extractBetween(filename,"ECMWF_U-","-0-0.tif");
    timestamp{timeidx} = datetime(timestring,"InputFormat","yyyyMMddHHmmssSSS","Format","yyyy-MM-dd HH:mm");
    [Utmp,~] = readgeoraster(filename);
    U(:,:,timeidx) = Utmp;
    vfilename = replace(filename,"U" + filesep + "ECMWF_U","V" + filesep + "ECMWF_V");
    [Vtmp,~] = readgeoraster(vfilename);
    V(:,:,timeidx) = Vtmp;
    timeidx = timeidx + 1;
end
U(isnan(U)) = 0;
V(isnan(V)) = 0;

%% Calculate grid

lonstart = min(LON,[],'all');
lonend = max(LON,[],'all');
lonsize = abs(lonstart - lonend);
latstart = min(LAT,[],'all');
latend = max(LAT,[],'all');
latsize = abs(latstart - latend);
cellsize = [lonsize/(gridsize(2)-1) latsize/(gridsize(1)-1)];
clearradius = sqrt(cellsize(1)^2+cellsize(2)^2)/5;
gridlength = prod(gridsize);

%% Assign particle structure

try clear particle; catch; end
if numquivers == 0
    numquivers = gridlength;
end

varTypes = ["double","double","logical","uint64","double","double"];
varNames = ["lat","lon","active","age","u","v"];
sz = [numquivers numel(varNames)];
particle = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

if regulargrid
    latvec = reshape(LAT,1,[]);
    lonvec = reshape(LON,1,[]);
    for partidx = 1:numquivers
        particle.lat(partidx) = latvec(partidx);
        particle.lon(partidx) = lonvec(partidx);
    end
else
    latvec = reshape(LAT,1,[]);
    lonvec = reshape(LON,1,[]);
    particle.lat = latstart + (latend-latstart) * rand(numquivers,1);
    particle.lon = lonstart + (lonend-lonstart) * rand(numquivers,1);
end

hold on;
particle_h = []; % Initialize array of particle handles

%% Plot particles and calculate new positions based on U & V

for timeidx = 1:iteratelimit
    % Calculate velocity vector
    LATflip = flip(LAT,1);           % need to flip for interp2
    Uflip = flip(U(:,:,timeidx),1);  % need to flip for interp2
    Vflip = flip(V(:,:,timeidx),1);  % need to flip for interp2

    partvel_U = interp2(LON,LATflip,double(Uflip),particle.lon,particle.lat);
    partvel_V = interp2(LON,LATflip,double(Vflip),particle.lon,particle.lat);

    % Assemble velocity vector matrices
    particle.u = partvel_U;
    particle.v = partvel_V;

    % Update title
    title(string(timestamp{timeidx}));

    % Update age
    particle.age = particle.age + 1;

    % Update quivers
    if timeidx > 1
        delete(quiverh);
    end
    quiverh = quiverm(particle.lat,particle.lon,particle.v,particle.u,'c',1);
    % To color the quivers using RGB you can use the following
    % set(quiverh,'Color',[0 1 1]);

    % Update
    drawnow;

    % Calculate Next Position
    particle_lon_next = particle.lon + speedfactor * particle.u;
    particle_lat_next = particle.lat + speedfactor * particle.v;
    particle.lon = particle_lon_next;
    particle.lat = particle_lat_next;

    % Check of out of range and mark those as inactive
    lonoutofrange = (particle.lon < lonstart) | (particle.lon > lonend);
    latoutofrange = (particle.lat < latstart) | (particle.lat > latend);
    particle.active = ~(lonoutofrange | latoutofrange);

    % Reassign inactive particles
    for idx = 1:numquivers
        if ~particle.active(idx)
            particle.age(idx) = 0;
            particletooclose = true;
            searchidx = 0;
            while particletooclose
                particle.lat(idx) = latstart + (latend-latstart) * rand;
                particle.lon(idx) = lonstart + (lonend-lonstart) * rand;
                % Add check to see if this particle is close to any other active particles
                latdist = particle.lat(idx) - [particle.lat];
                londist = particle.lon(idx) - [particle.lon];
                particledist = sqrt(latdist.^2 + londist.^2);
                particledist = particledist(particle.active); % remove distance of inactive particles
                if min(particledist) > clearradius
                    particletooclose = false;
                else
                    searchidx = searchidx + 1;
                    %disp([num2str(searchidx) ' searching for new position'])
                end
            end
        end
    end

    if recordmovie
        M(timeidx) = getframe(gcf);  % for recording movie
    end
end


%% Record movie

if recordmovie
    % create the video writer with 1 fps
    writerObj = VideoWriter(moviefilename,'Uncompressed AVI');
    writerObj.FrameRate = 10;
    % set the seconds per image
    % open the video writer
    open(writerObj);
    % write the frames to the video
    for i=1:length(M)
        % convert the image to a frame
        frame = M(i) ;
        writeVideo(writerObj, frame);
    end
    % close the writer object
    close(writerObj);
end