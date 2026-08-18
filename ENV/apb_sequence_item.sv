`ifndef APB_SEQUENCE_ITEM
`define APB_SEQUENCE_ITEM

virtual class apb_sequence_item;

    pure virtual function void copy(apb_sequence_item rhs);
    pure virtual function void print(string id, apb_sequence_item exp = null);
endclass

`endif
