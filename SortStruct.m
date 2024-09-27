% SortStruct: serve solo per ordinare in ordine alfabetico la struttura
% data_processing

function data_processing = SortStruct(data_processing)
if size(data_processing,1) > 1
    % Convert to cell
    Afields = fieldnames(data_processing);
    Acell = struct2cell(data_processing);
    sz = size(Acell)
    % Convert to a matrix
    Acell = reshape(Acell, sz(1), []);
    % Make each field a column
    Acell = Acell';
    % Sort by first field "name"
    Acell = sortrows(Acell, 1)
    % Put back into original cell array format
    Acell = reshape(Acell', sz);
    % Convert to Struct
    data_processing = cell2struct(Acell, Afields', 1); 
end
end