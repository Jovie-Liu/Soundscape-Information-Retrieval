function fsnd = freesound(newDataDirectory)
% -------------------------------------------------------------------------
% Example usage. First create instance freesound()
%
% ex. 1
% fsnd = freesound('/Volumes/THP-SAMPLES/Samples/freesound/flyover');
% fsnd.save2FileAll('flyover');
%
% ex 2.
% fsnd = freesound();
% fsnd.save2FileAll('city+siren');
%
% Tae Hong Park
% NYU
% thp1@nyu.edu
% 2012
% -------------------------------------------------------------------------
fsnd = struct('queryDB', @queryDB, 'getData2', @getData2, ...
              'getAllTags', @getAllTags, 'save2File', @save2File, ...
              'save2FileAll', @save2FileAll, ...
              'setDataDirectory' ,@setDataDirectory, ...
              'checkDownloadedFiles', @checkDownloadedFiles, ...
              'convertToPCM', @convertToPCM, ...
              'segmentIntoMaxSec', @segmentIntoMaxSec, ...
              'standardize', @standardize, 'crossCheck', @crossCheck, ...
              'downloadAudioWithId', @downloadAudioWithId);

sfiles = constFreesound();
  
% The elements of the Freesound API call
%base_url    = 'https://www.freesound.org/apiv2/sounds/search/text/';
base_url    = 'http://www.freesound.org/apiv2/search/text/';
api_key     = 'token=dnkTkIG8zGroCn6zpnCtdnI8HvbOEU8QTE4UejIb';
query       = 'query=';
and         = '&';
quest       = '?';
format      = 'format=json';
normalFilter = 'filter=';
%type        = 'f='; %'f=type:wav'; % filter
%duration    = []; %'f=duration:[`0 TO 100`]';%duration:[0.1 TO 0.3]'; 'f=id:75909'
duration    = 'duration:[4.0 TO 1800.0]';
sorted      = 's=score';
download    = 'download';
defaultAudioExt = '.wav';
maxNumOfSounds  = [];%500; % parameter to set max number of files to download
allowedDurInSecs = 60*10;
allowedExtensions = {'.wav', '.ogg', '.flac', '.au', '.aiff', '.aif', ...
                       '.aifc', '.mp3', '.m4a', '.mp4'}; 

dbQuery           = [];
dbQuery.URL       = [];
dbQuery.string    = [];

% oAuthorizatio 2 stuff
oAuth.client.id                = '2mp7pjUSf2qptmpyMIlu';
oAuth.client.secretApiKey      = 'UvWw7rdy1ukCjY3E5B6Fif9kKeHwzqOaJYDEpSiy';
oAuth.url.redirect             = 'https://www.freesound.org/home/app_permissions/permission_granted/';
aAuth.url.authCode             = ['https://www.freesound.org/apiv2/oauth2/authorize/?client_id=', oAuth.client.id, '&response_type=code'];
aAuth.url.accessToken          = [];
oAuth.code.authorization       = [];
oAuth.code.accessToken         = [];

subDir                         = [];
dataDir                        = './data/';

strPattern = '<div style="font-size:14px;font-family:''Courier'';">';
len = length(strPattern);

stratch = [];
stratch.file.cnt = 0;

if nargin < 1        
    if isempty(dir(dataDir))
        mkdir(fullfile(dataDir))
        disp('Create data directory where this file is saved: ./data ')
        return;
    end
else
    dataDir = [newDataDirectory filesep];
    
    if isempty(dir(dataDir))
        try 
            disp('Attemping to create new directory ...')
            mkdir(newDataDirectory)
            disp(['Created new directory: ' newDataDirectory])
        catch ME
            disp(['Could not create new directory: ' newDataDirectory])
            ME
        end
    else
        disp(['Directory: ' newDataDirectory, ' exists.'])
    end    
end

    function setDataDirectory(newDirectory)
        dataDir = [newDirectory filesep];
    end
return
% -------------------------------------------------------------------------
% Step 1: Get authorization 
% Step 2: Get access Token
% Step 3: Download Audio
% -------------------------------------------------------------------------
function [status, results, authCode, accessToken] = oAuthorizationInit()
    status      = 1;
    results     = [];
    authCode    = [];
    accessToken = [];
    
    [statusA, authCodeA]    = getAuthorization();        
    [statusB, accessTokenB] = getAccessToken();
    
    % test if success
    if (statusA == 0) && (statusB == 0)
        status = 0;
        authCode    = authCodeA;
        accessToken = accessTokenB;
    end
end

function [status, audioFileBin] = downloadAudioWithId(audioId, ...
                                                      fullDirAndFile)
    status  = 1;
            
    if isnumeric(audioId)
        audioId = num2str(audioId);
    end
    
    disp('downloading ...');
    tic
    theURL = fullfile('https://www.freesound.org/apiv2/sounds/', ...
                      audioId, ...
                      '/download/');
                  
    theCommand = ['curl ', ...
                  '-o ', fullDirAndFile, ' ', ...  
                  '-H "Authorization: Bearer ', ...
                  oAuth.code.accessToken, '" ', theURL];     

   [status, audioFileBin] = system(theCommand);          
   disp(['download time (sec): ' num2str(toc)])
end

function [status, results] = getAuthorization()
    results = [];

    url = strcat(aAuth.url.authCode);
    [status, h] = web(url);

    lastAuthCode = [];
    curAuthCode  = [];

    t0              = tic;
    timedOut        = false;
    timeOutDurInSec = 10;
    authCodeLen     = 30;

    browserFirstLaunch = false;

    while(true)
        htmlResponse = get(h, 'HtmlText');
        idx = strfind(htmlResponse, strPattern) + len;
        curAuthCode = htmlResponse(idx:(idx+authCodeLen-1));

        if isempty(curAuthCode)
            browserFirstLaunch = true;
            % first time here after web browser is launched
            continue;
        end

        if browserFirstLaunch 
            if ~isempty(curAuthCode)
                oAuth.code.authorization = curAuthCode;
                break;
            end
        else
            if isempty(lastAuthCode)
                continue;
            else
                lastAuthCode = curAuthCode;        
                break;            
            end
        end

        drawnow;

        if (toc-t0) > timeOutDurInSec
            timedOut = true;
            break;
        end
    end

    if timedOut
        oAuth.code.authorization = [];
        disp(['timed out: ' num2str(toc-t0)]);
        results = [];
    else
        oAuth.code.authorization = curAuthCode;
        disp(['received authorization code: ', curAuthCode]);
        results = oAuth.code.authorization ;
    end        
end

function [status, accessToken, results] = getAccessToken()
    status      = 1;
    results     = [];
    accessToken = [];
    
    aAuth.url.accessToken = ...
             ['curl -X POST -d "client_id=', oAuth.client.id , ...
              '&client_secret=', oAuth.client.secretApiKey ,...
              '&grant_type=authorization_code', ...
              '&code=', oAuth.code.authorization, '" ', ...
              'https://www.freesound.org/apiv2/oauth2/access_token/'];

    % results in json text format      
    [status, results] = system(aAuth.url.accessToken); 

    if status == 0 
        % encode into cell so we can easily use in Matlab
        results                = parse_json_two(results);
        oAuth.code.accessToken = results.access_token;
        accessToken            = results.access_token;
    end
end

function soundCell = queryDB(queryString, pageNumber)
    option = [];
    
    if nargin == 0
        return;
    elseif nargin == 1
        option = [];
    elseif nargin == 2
        if pageNumber ~= 1
            option = strcat(and, 'page=', num2str(pageNumber));
        end
    end
    
    baseURL = ...
        strcat(base_url, quest, api_key, and, query, queryString, ...
               and, normalFilter, duration, ...
               and, sorted, ...
               and, format);        

    disp(baseURL);       
    %-Read the url
    baseURL = strrep(baseURL, ' ', '%20');
    url = urlread(strcat(baseURL, option));

    % Read in the json-struct: this will return all of the query 
    % results in Matlab struct format
    soundCell = parse_json_two(url);    
    disp(soundCell)
    
    ii = 1;
end

function soundCellOut = getNextPage(soundCellIn, pageNumber)
    soundCellOut = [];
    
    if isempty(soundCellIn.next)
        return;
    end    
    
    soundCellOut = queryDB(dbQuery.string, pageNumber);    
end

function audioData = queryDBAudioDownload(id)
    catUrl = strcat(base_url, quest, api_key, and, query, queryString, ...
                    and, normalFilter, duration, ...
                    and, sorted, ...
                    and, format);
end
% -------------------------------------------------------------------------
% This function is used to get all tags from queryString
% -------------------------------------------------------------------------
function getAllTags(queryString)
    soundCell = queryDB(queryString);   
    
    for p=1:soundCell.num_pages
        
        % number of samples per page
        numOfSamples = length(soundCell.sounds); 
        
        % samples for each page
        for j = 1:numOfSamples   
            %-Convert them to matrix form
            soundStruct = cell2mat(soundCell.sounds(j));
            disp([num2str(soundStruct.id), ...
                  num2str(sprintf('%0.2f', soundStruct.duration/60)), ...
                  soundStruct.tags ])           
        end
        
        % get next page
        soundCell = getPage(soundCell);
    end
    
    disp(['Found ' num2str(soundCell.num_results) ' samples.'])
end

% -------------------------------------------------------------------------
% This subfunction is used to call multi-page queries. It is used
% save2FileAll()
% -------------------------------------------------------------------------
function soundCellNext = getPage(soundCell, pageNumber)
    soundCellNext = [];
    
    if isempty(soundCell.next)        
        return;
    end
    
    soundCellNext = queryDB(dbQuery.string, pageNumber);
end

% -------------------------------------------------------------------------
% This function is used to call the the save2File() function. This can be
% used to download all files from queryString. For exampls queryString =
% 'NYC+siren' will download any hits that has NYC and siren.
% -------------------------------------------------------------------------
function save2FileAll(queryString)
    % create new directory with query string
    subDir         = queryString;
    dbQuery.string = queryString;
    
    temp = dir(fullfile(dataDir, subDir));
    
    if isempty(temp)
        mkdir(fullfile(dataDir, subDir));
    end
    
    soundCell = queryDB(queryString);   
    
    skippedDownloads = 0;
    numOfSoundsPerPage = length(soundCell.results);   
    numOfPages         = floor(soundCell.count/numOfSoundsPerPage);
    
    % set num of pages according to user defined max download limits or
    % download all files
    if ~isempty(maxNumOfSounds)
        reqNumOfPages = maxNumOfSounds/numOfSoundsPerPage;        
        
        if numOfPages > reqNumOfPages
            numOfPagesFinal = reqNumOfPages;
        else
            numOfPagesFinal = numOfPages;
        end
        
    else
        numOfPagesFinal = numOfPages;
    end
    
    
    disp(' ');
    disp(['sounds/page            : ', num2str(numOfSoundsPerPage)])
    disp(['total number of sounds : ', num2str(soundCell.count)]);
    disp(['number of total pages  : ', num2str(numOfPages)]);    
    disp(['number of final pages  : ', num2str(numOfPagesFinal)]);
    disp(' ');
    
    % oAuthorization 2 required for freesound down/upload of files. Session
    % is permitted for 24 hours
    aAuthInit = oAuthorizationInit();
    
    if aAuthInit ~= 0
        return;
    end
    
    stratch.file.cnt = 0;
    
    %for p=1:soundCell.num_pages        
    for page=1:numOfPagesFinal        
        %soundCell = getPage(soundCell, page);        
        if isempty(soundCell)
            continue;
        end
        
        % number of samples per page
        numOfSamples = length(soundCell.results); 
        disp(['page ' num2str(page) '/' num2str(numOfPagesFinal) ...
              ', samples: ' num2str(numOfSamples)]);
        
        % samples for each page
        %if tagFilter inside the cell then skip
        %    continue;
        %else
            skippedDownloads = skippedDownloads + save2File(soundCell);
        %end
        
        soundCell = getNextPage(soundCell, page+1);
    end
    
    disp(' ')
    disp(['Skipped samples: ' num2str(skippedDownloads)])
end

% -------------------------------------------------------------------------
% This function saves to file requested audio samples from freesound.
% soundCell is a Matlab cell containing basic information which can be used
% to download
% -------------------------------------------------------------------------
function skippedDownloads = save2File(soundCell)
    metadataOnly     = false;    
    skippedDownloads = 0;   
    numOfSamples     = length(soundCell.results);
    
    len = length(allowedExtensions);
    
    for j=1:numOfSamples          
        %-Convert them to matrix form
        soundStruct = soundCell.results{j};    

        % this part allows for skipping of files (exisiting filenames) so
        % that downloading is faster - existing files will not be
        % downloaded
        % -----------------------------------------------------------------
        [~, name, ext] = fileparts(soundStruct.name);
        
        if isempty(ext)
            disp('No file extension. Skipping')
            disp(soundStruct.name);
            continue;
        end
        
        notAllowedExtension = true;        
        for kk=1:len
            if strcmpi(allowedExtensions{kk}, ext)
                notAllowedExtension = false;
                break;
            end
        end
        
        if notAllowedExtension
            disp('Not allowed extension. Skipping')
            disp(soundStruct.name);
            continue;
        end
        
        filterTags = {'car';'train';'truck';'traffic';'horn';'siren';...
            'bird';'water';'fire';'rain';'storm';'thunder';'voice';...
            'speak';'yell';'talk';'plane';'noise';...
            'music';'vocal';'cat';'people';'human';'child';'kid'};


        l = length(filterTags);
        indicator = true;
        len_tags = length(soundStruct.tags);
        for num = 1: len_tags
            tag = lower(soundStruct.tags{num});
            for filter = 1:l
                if ~isempty(strfind(tag,filterTags{filter}))
                    disp('Mismatching tags. Skipping')
                    disp(tag)
                    disp(soundStruct.name)
                    disp(' ')
                    indicator = false;
                    break;
                end
            end
            if indicator == false
                break;
            end
        end
        
        if indicator == false
            skippedDownloads = skippedDownloads + 1;
            continue;
        end
        
        nameOrig = name;
        %name = regexprep(name,'[^[]-#a-zA-Z_0-9.@:,;()&*|+ ]','_');
        %name = strrep(name,' ','_');
        name = strrep(name, ' ', '\ ');
        
        soundStruct.name = strcat(name, ext);
        
        if ~isempty(dir(fullfile(dataDir, subDir, strcat(nameOrig, ext)))) || ...
           metadataOnly             
            disp(['File exists: ', soundStruct.name]);
            continue;
        end
                        
        % create URL and download audio file from freesound
        % -----------------------------------------------------------------
%         tags = lower(soundStruct.tags);
%         bird = strfind(tags,'people');
%         
%         for count = 1:length(bird)
%             if ~isempty(bird{count})
                
                try
                    disp(['writing ' num2str(j), '/', num2str(numOfSamples), ': '...
                        soundStruct.name])
                    
                    metadata = [];
                    
                    fullDirAndFile = fullfile(dataDir, subDir, soundStruct.name);
                    
                    if ~metadataOnly
                        [status, audioFileChar] = ...
                            downloadAudioWithId(soundStruct.id, fullDirAndFile);
                    end
                    
                    % save labels and any other information to .mat file
                    
                    if strcmpi(nameOrig, soundStruct.name)
                        metadata.filenameOrig = [];
                    else
                        metadata.filenameOrig = nameOrig;
                    end
                    
                    metadata.filename     = soundStruct.name;
                    metadata.id           = soundStruct.id;
                    metadata.tags         = soundStruct.tags;
                    
                    %save(fullfile(dataDir, subDir, strcat(name, '.mat')), 'metadata');
                    save(fullfile(dataDir, subDir, strcat(nameOrig, '.mat')), 'metadata');
                    stratch.file.cnt = stratch.file.cnt + 1;
                    
                    disp(['snds/total sounds: ', ...
                        num2str(stratch.file.cnt), '/', num2str(soundCell.count)]);
                    disp(['saved: ' soundStruct.name])
                    disp(' ')
                catch e
                    skippedDownloads = skippedDownloads + 1;
                    disp(e)
                    disp(['*** couldn`t download: ' soundStruct.name]);
                end
                
                break;
            end
        end
        
%     end        
% end

% -------------------------------------------------------------------------
% Check downloaded files to make sure they are all working:
% Make mono, standardize fs, bit resolution, etc.
% -------------------------------------------------------------------------
function checkDownloadedFiles(newDataDirectory)
    % check files in specfied directory, otherwise use current data
    % directory already set
    if nargin >= 1
        tempDir = [newDataDirectory filesep];
        
        if isempty(dir(tempDir))
            disp(['No such directory: ' newDataDirectory])    
            return;
        else
            dataDir = tempDir;
        end
    end    
    
    % these should probably be input arguments
    fs      = 44100;
    mono    = 1;
        
    % do analysis
    standardize(fs, mono);
    crossCheck();
end

% -------------------------------------------------------------------------
% This funcion standardizes all the audio samples to sampling rate fs and
% mono state. For example, we can set fs = 44100 and mono = true. This will
% convert/resample all samples to fs and 1 channel audio.
% -------------------------------------------------------------------------
function standardize(fs, mono)
    theDir = dir([dataDir, '*.mat']);    
    numOfSuccess = 0;
    
    for i=1:length(theDir)
        fullDir = [dataDir, theDir(i).name];
        header = load([fullDir]);
        
        if i == 58
            i;
        end
        
        if (mono)
            tags        = header.tags;
            metadata    = header.metadata;

            % remove all files without extensions
            % -------------------------------------------------------------
            [pth, name, ext] = fileparts([dataDir, metadata.filename]);

            if isempty(ext)
                %delete([dataDir, metadata.filename, ext]);
                continue;
            end
            
            % make stereo into mono files and remove/overwrite mono files
            % -------------------------------------------------------------
            %if metadata.channels > 1 
            % the stored metadata is sometimes incorrectly inputted by user
            % and hence cannot trust it.
            try
                fSize = audioread([dataDir, metadata.filename], ...
                                                [], [], [], [], 1);
            catch ME
                % remove files that cannot be read
                disp(['problem in audioread, reading file size: ' ...
                    num2str(i)]);
                ME
                
                delete([dataDir, name, ext]);
                delete([dataDir, name, '.mat']);                
            end
            
            if fSize(2) > 1
                try
                    disp(['converting to mono: ' metadata.filename ', ' num2str(i)])

                    % get extension from file and over/write as wave file
                    [pathstr, name, ext] = ...
                        fileparts([dataDir, metadata.filename]);
                    
                    % read file and make mono
                    [x, fs] = audioread([dataDir, metadata.filename]);
                    x       = dsp.makeMono(x);                    
                    
                    audiowrite(x, fs, [dataDir, name, defaultAudioExt]);

                    % remove the non-wav file as the default will be
                    % written as a wav file
                    if ~strcmpi(ext, defaultAudioExt)
                        delete([dataDir, name, ext]);
                    end
                    
                    % housekeeping and update metadata
                    metadata.channels   = 1;    
                    metadata.filename   = [name, defaultAudioExt];
                    numOfSuccess        = numOfSuccess + 1;
                    
                    save(fullDir, 'tags', 'metadata');
                    disp(['converted and saved: ' metadata.filename])                    
                catch
                    % delete corrupt media file and associated .mat file
                    % -----------------------------------------------------
                    disp(['*** problem reading/writing (i): ' ...
                        metadata.filename '(' num2str(i) ')'])
                    disp('*** deleting media and .mat file.')
                    
                    delete([dataDir, name, ext]);
                    delete([dataDir, name, '.mat']);
                end
                
                disp('.')
            end
        end
    end
    
    disp(['number of conversions writes: ' ...
           num2str(numOfSuccess) '/' num2str(length(theDir))])
end

% -------------------------------------------------------------------------
% Function to cross-check between .mat files and actual media files:
% sometimes there are no media+mat file pairs, sometimes metadata from
% freesound is not correct - 2 ch is actually 1 channel etc.
% Delete .mat files without media files
% Some issues occur when we have file names that use special characters:
% eg. French accent etc. Not sure how to delete - when we read using Matlab
% function the results all ignore accent etc. so it's impossible to use
% functions provided to remove or rename at this time.
% -------------------------------------------------------------------------
function crossCheck()
    theDir              = dir([dataDir, '*.mat']);    
    numOfMatFiles       = length(theDir);    
    numOfAddExtensions  = 0;
    numOfDeletions      = 0;
    
    % Check starting with all available .mat files (contains associated
    % file names and other metadata). Check if we have corresponding media
    % files and rename if media files have no extensions
    % ---------------------------------------------------------------------
    for i=1:numOfMatFiles
        fullFilename = [dataDir, theDir(i).name];
        header       = load(fullFilename);
        
        tags        = header.tags;
        metadata    = header.metadata;
        
        [pth, name, ext] = fileparts([dataDir, metadata.filename]);
 
        % if no extension for media file but .mat file do exist, rename 
        % using extensions found in metadata if it exists
        % -----------------------------------------------------------------
        if isempty(ext) || strcmp(ext, '.')
            
            % some sort of media extension type found in metadata .mat
            % file, like '.'. This happens when the filename is too long
            % and gets automatically truncated
            if ~isempty(metadata.type)                 
                % have max size of filename be 112 long. Cut down to 108.
                % this sometimes occurs when filename is too large where
                % ext gets removed and only . remains
                if length(metadata.filename) >= 112
                    metadata.filename = metadata.filename(1:108);
                end
                
                try 
                    % rename file with extension
                    movefile(fullfile(pth, metadata.filename), ...
                    fullfile(pth, [metadata.filename,  '.', metadata.type]))

                    % update metadata.filename and save to .mat header file
                    metadata.filename   = ...
                        [metadata.filename, '.', metadata.type];
                    
                    header.metadata     = metadata.filename;
                    save([dataDir, name, '.mat'], 'tags', 'metadata');

                    % add extension of media file and try to load if it
                    % actually works. If so keep, it not readable remove
                    % both .mat and media file
                    try 
                        audioread(metadata.filename);
                    catch
                        % remove as this extension-less media file is
                        % corrupt and cannot be read
                        delete([dataDir, metadata.filename])
                        delete([dataDir, name, '.mat'])
                    end
                    
                    numOfAddExtensions = numOfAddExtensions + 1;                    
                catch
                    disp('renaming media file with extension failed')
                end
            else
                % remove .mat file if there is no extension information in 
                % header file as we don't know what file type it is
                try
                    delete(fullFilename)
                    numOfDeletions = numOfDeletions  + 1;
                    disp('no extension in metadata, removing extensionless file: success')
                catch
                    disp('no extension in metadata, removing extensionless file: fail')
                end                
            end
        end        
    end
    
    % Here we check for any remaining media files tha do not have
    % associated .mat files. Check for media files and see if they have 
    % associated .mat files. If we have enough information, create .mat 
    % header files    
    % ---------------------------------------------------------------------
    theDir     = dir(dataDir);    
    numOfFiles = length(theDir);          
    
    for i=1:numOfFiles
        % get file names etc. directly from dir command
        [dmmy, name, ext] = fileparts(theDir(i).name);

        % check all files that are not .mat && not a directory: look for 
        % media files w/o .mat header files
        if ~strcmpi(ext, '.mat') && ~theDir(i).isdir %~strcmpi(ext, '.')             
            results = dir([dataDir, name, '.mat']); % check if .mat exists
            
            if isempty(results)
                % no matching .m file, check if we allowable file extension
                foundMatch = false;
                
                % check for media extensions that are allowed. These are 
                % defined in the constFressound.m file.
                for k=1:length(sfiles)
                    if strcmp(ext, sfiles(k).ext)
                        foundMatch = true;
                        break;
                    end
                end

                % This is a case where have a media file w/o a metadata
                % file: probably should fix this during download later                 
                % create new metadata struc in order to create a
                % .mat header file for this media file.                
                if foundMatch
                    try
                        % -------------------------------------------------
                        % copy and clear all struct fields in metadata
                        temp = metadata;
                        temp(1) = [];

                        % populate with new information
                        [fSize fs] = ...
                            audioread([dataDir, name, ext], [], [], [], [], 1);
                        
                        % need (1) when struct is empty  
                        temp(1).analysis_sample_rate = fs; 
                        temp.filename = [name, ext];
                        temp.type = ext(2:end);     
                        temp.channels = fSize(2);
                        temp.length = fSize(1)/fs;
                        
                        tags     = [];
                        metadata = temp;                        
                        save([dataDir, name, '.mat'], 'tags', 'metadata');
                        
                        disp('creating mat from media: success')     
                    catch  
                        % catch all instances that fails during I/O for
                        % whatever reason
                        try
                            temp = delete([dataDir, name, ext]);
                            disp('creating mat from media: fail, deleted')
                        catch
                            disp('creating mat from media: fail, special language character issue')
                        end                        
                    end                    
                else
                    disp([num2str(i) ' No .mat, NO   ext: ', name, ext])
                end                
            end
        end
    end
    
    disp(' ')
    disp(['number of extensions add: ' num2str(numOfAddExtensions)])
    disp(['number of deletions (no extensions available): ' num2str(numOfAddExtensions)])
end

function convertToPCM(theDir)
% allowedExtensions = {'.wav', '.ogg', '.flac', '.au', '.aiff', '.aif', ...
%                        '.aifc', '.mp3', '.m4a', '.mp4'}; 
                   
    files = dir(theDir);
    len = length(files);
    
    for k=1:len
        [~, nam, ext] = fileparts(files(k).name);        
        
        if strcmpi(ext, '.mp3')
            saveAsWave();
        elseif strcmpi(ext, '.ogg')
            saveAsWave();
        elseif strcmpi(ext, '.flac')
            saveAsWave();
        end        
    end    
    
    function saveAsWave()
        [temp, fs] = audioread(strcat(nam, ext));
        audiowrite(strcat(nam, '.wav'), temp, fs);                    
        mkdir('orig');
        movefile(strcat(nam, ext), fullfile('orig', strcat(nam, ext)));
        disp(['saved: ', strcat(nam, ext), ' to ', strcat(nam, '.wav'), ...
              ', orig moved to ', './orig']);
    end
end

function segmentIntoMaxSec(theDir)
    files = dir(theDir);
    len   = length(files);
    len1  = length(allowedExtensions);    
    
    for k=1:len
        [~, nam, ext] = fileparts(files(k).name);        
        
        for j=1:len1
            if strcmpi(ext, allowedExtensions{j})
                % found allowed audio extension
                info = audioinfo(files(k).name);
                
                numOfSegs = info.Duration/allowedDurInSecs;
                
                if numOfSegs > 1
                    disp(' ');
                    
                    allowedDurInSamps = allowedDurInSecs*info.SampleRate;
                    
                    startIdx  = 1;
                    endIdx    = allowedDurInSamps;
                    numOfSegs = ceil(numOfSegs);
                    
                    for seg = 1:numOfSegs                                           
                        temp = audioread(strcat(nam, ext), ...
                                         [startIdx, endIdx]);                                                    

                        audiowrite(strcat(nam, ...
                            '.satb.', num2str(seg), '.wav'), temp, ...
                            info.SampleRate);                    
                        
                        disp(['saved: ', strcat(nam, ext), ' to ', ...
                            strcat(nam, '.satb.', num2str(seg), '.wav')]);

                        
                        if seg == (numOfSegs-1)
                            % last segment may not be full segment
                            startIdx = startIdx + allowedDurInSamps;
                            endIdx   = info.TotalSamples;                            
                        else
                            startIdx = startIdx + allowedDurInSamps;
                            endIdx   = endIdx + allowedDurInSamps;                            
                        end
                    end
                    
                    mkdir('orig');
                    movefile(strcat(nam, ext), fullfile('orig', strcat(nam, ext)));
                    disp(['orig full file moved to ', './orig']);
                end
                
                break;
            end
        end        
    end        
end

end


function sfiles = constFreesound
    % constants for freesound
    sfiles(1).ext = '.mp3';
    sfiles(2).ext = '.m4a'; 
    sfiles(3).ext = '.aac';
    sfiles(4).ext = '.mp4';
    sfiles(5).ext = '.wav';
    sfiles(6).ext = '.flac';
    sfiles(7).ext = '.aif';
    sfiles(8).ext = '.aiff';
end

