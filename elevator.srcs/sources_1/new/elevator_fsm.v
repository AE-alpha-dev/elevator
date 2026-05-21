// ºËÐÄ×´Ì¬Ä£¿é
module elevator_fsm (
    input  wire       clk       ,       
    input  wire       rst_n     ,     
    input  wire       sys_en    ,    
    input  wire [3:0] key       , 
    input  wire       tick_3s   ,    
    input  wire       tick_4s   ,    
    output wire       timer_en  ,    
    output wire [3:0] elv_state , 
    output reg  [1:0] floor  
);

    parameter STAY1 = 4'b0001, UP = 4'b0010, STAY2 = 4'b0100, DOWN = 4'b1000;
    reg [3:0] current_state, next_state;
    reg       req_up, req_dn;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            current_state <= STAY1;
        else if (!sys_en) 
            current_state <= current_state; 
        else 
            current_state <= next_state;
    end

    always @(*) begin
        next_state = current_state; 
        case (current_state)
            STAY1   : if (req_up)  next_state = UP;
            STAY2   : if (req_dn)  next_state = DOWN;
            UP      : if (tick_4s) next_state = STAY2;
            DOWN    : if (tick_4s) next_state = STAY1;
            default :              next_state = STAY1;
        endcase
    end

    assign elv_state = current_state; 
    assign timer_en  = (current_state == UP) || (current_state == DOWN); 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            floor <= 2'd1;
        else if (!sys_en) 
            floor <= floor; 
        else begin
            if (current_state == STAY1) 
                floor <= 2'd1;
            else if (current_state == STAY2) 
                floor <= 2'd2;
            else if (current_state == UP && tick_3s) 
                floor <= 2'd2; 
            else if (current_state == DOWN && tick_3s) 
                floor <= 2'd1; 
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            req_up <= 1'b0; 
            req_dn <= 1'b0; 
        end 
        else if (!sys_en) begin 
            req_up <= req_up; 
            req_dn <= req_dn; 
        end 
        else begin
            if (current_state == UP || current_state == STAY2) 
                req_up <= 1'b0; 
            else if (key[1] == 1'b0 || key[3] == 1'b0) 
                req_up <= 1'b1;

            if (current_state == DOWN || current_state == STAY1) 
                req_dn <= 1'b0; 
            else if (key[0] == 1'b0 || key[2] == 1'b0) 
                req_dn <= 1'b1;
        end
    end

endmodule