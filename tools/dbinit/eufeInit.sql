attach database :memory as eufe;
.read "./eufe/eufe.sql"
.backup eufe eufe.sqlite