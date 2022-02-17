function data_timetable = import_from_movebank(study_ID)
    % Download data using Movebank's REST API 
    % Downloads the basic set of variables for a study
    % Login credentials should be specified in movebank_credentials.txt
    % 
    % Args: 
    %     study_ID (char): Movebank study_ID
    % 
    % Returns: 
    %     timetable: MATLAB timetable of Movebank data

    [username, password] = read_movebank_credentials();
    base_url = 'https://www.movebank.org/movebank/service/direct-read';
    options = weboptions('Username', username, 'Password', password);
    data = webread(base_url, 'entity_type', 'event', 'study_id', study_ID, ...
    'attributes', ['individual_local_identifier,tag_local_identifier,timestamp,' ...
    'location_long,location_lat,visible,individual_taxon_canonical_name'], ...
    options);
    data_timetable = table2timetable(data, 'RowTimes', 'timestamp');
end 

function [username, password] = read_movebank_credentials()
    % Read in MoveBank login credentials from file 
    % Login credentials should be specified in movebank_credentials.txt
    
    % Returns: 
    %   char: username
    %   char: password

    [username, password] = readvars("movebank_credentials.txt", Delimiter =',', Range=4);
    username = char(username);
    password = char(password);
end 