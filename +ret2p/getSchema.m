function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'ret2p', 'pberens_retina2');
end
obj = schemaObject;
