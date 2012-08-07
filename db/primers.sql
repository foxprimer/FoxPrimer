--
-- Create a database for the storage and display of qPCR primers
--

CREATE TABLE primers ( Primer_Type  TEXT, Description   TEXT, mRNA  TEXT, Primer_Pair_Number    TEXT, Left_Primer_Sequence  TEXT, Right_Primer_Sequence TEXT, Left_Primer_Tm    NUMERIC, Right_Primer_Tm    NUMERIC, Left_Primer_Coordinates    TEXT, Right_Primer_Coordinates  TEXT, Product_Size  NUMERIC,    Product_Penalty NUMERIC, Left_Primer_Position   TEXT, Right_Primer_Position TEXT, PRIMARY KEY ( Left_Primer_Sequence, Right_Primer_Sequence, mRNA));
