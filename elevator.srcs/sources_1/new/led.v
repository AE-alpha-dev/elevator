// LED ÏÔÊ¾Ä£¿é
module led_ctrl (
    input  wire       clk       ,
    input  wire       rst_n     ,
    input  wire       sys_en    ,
    input  wire [3:0] elv_state ,
    input  wire [3:0] key       ,
    output reg  [3:0] led
);

    wire key0 = key[0];
    wire key1 = key[1];
    wire key2 = key[2];
    wire key3 = key[3];

    parameter STAY1 = 4'b0001, UP = 4'b0010, STAY2 = 4'b0100, DOWN = 4'b1000;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            led <= 4'd0;  
        else if (!sys_en)
            led <= led;
        else 
            case (elv_state)
                STAY1: begin 
                    led[0] <= 1'b0; 
                    led[2] <= 1'b0;
                    if (!key1) led[1] <= 1'b1;
                    if (!key3) led[3] <= 1'b1;
                end
                UP: begin
                    if (!key0) led[0] <= 1'b1;
                    if (!key1) led[1] <= 1'b1;  
                    if (!key2) led[2] <= 1'b1;
                    if (!key3) led[3] <= 1'b1;
                end
                STAY2: begin 
                    led[1] <= 1'b0; 
                    led[3] <= 1'b0;
                    if (!key0) led[0] <= 1'b1;
                    if (!key2) led[2] <= 1'b1;
                end
                DOWN: begin
                    if (!key1) led[1] <= 1'b1;  
                    if (!key3) led[3] <= 1'b1;
                end
                default: led <= 4'd0;  
            endcase
    end

endmodule