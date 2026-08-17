module edge_detector (
    input logic clk,
    input logic rst,
    input logic kb_clk_sync,
    output edge_found
    );

      logic kb_clk_sync_d;

    always_ff @(posedge clk) begin
        if (rst) begin
            kb_clk_sync_d <= 1'b1;
            edge_found    <= 1'b0;
        end
        else begin
            edge_found    <= kb_clk_sync_d & ~kb_clk_sync;
            kb_clk_sync_d <= kb_clk_sync;
        end
    end
endmodule

// TITLE: keyboard_top.sv
// PROJECT: Keyboard ModSy lab
// DESCRIPTION: Keyboard top level. Functionality of all modules are mentioned in the manual. All the required interconnects are already done, students only have to fill in SV code in the sub-modules!

`timescale 1ns/1ps

module keyboard_top (
    input logic clk,
    input logic rst,
    input logic kb_data,
    input logic kb_clk,
    output logic [7:0] sc,
    output logic [7:0] num,
    output logic [3:0] seg_en
    );

    // Interconnect signals
    logic kb_clk_sync, kb_data_sync;
    logic edge_found;
    logic [7:0] scan_code;
    logic valid_scan_code;
    logic [3:0] binary_num;
    logic [7:0] code_to_display;

    // Synchronize all input signals from keyboard
    sync_keyboard sync_keyboard_inst (
        .clk(clk),
        .kb_clk(kb_clk),
        .kb_data(kb_data),
        .kb_clk_sync(kb_clk_sync),
        .kb_data_sync(kb_data_sync)
        );

    // Detect the falling edge of kb_clk_sync.
    // Make sure to double check that this module is synthesizable!
    edge_detector edge_detector_inst (
        .clk(clk),
        .rst(rst),
        .kb_clk_sync(kb_clk_sync),
        .edge_found(edge_found)
        );

    // Convert serial kb_data_sync to parallel scan code
    // Make sure to not use edge_found as clock! (i.e. @(posedge edge_found))
    convert_scancode convert_scancode_inst (
        .clk(clk),
        .rst(rst),
        .edge_found(edge_found),
        .serial_data(kb_data_sync),
        .valid_scan_code(valid_scan_code),
        .scan_code_out(scan_code)
        );
    // Drive the LEDs with the shifted output
    assign sc = scan_code;

    // Controller, based on a state machine
    keyboard_ctrl keyboard_ctrl_inst (
        .clk(clk),
        .rst(rst),
        .valid_code(valid_scan_code),
        .scan_code_in(scan_code),
        .code_to_display(code_to_display),
        .seg_en(seg_en)
        );

    convert_to_binary convert_to_binary_inst (
        .scan_code_in(code_to_display),
        .binary_out(binary_num)
        );

    binary_to_sg binary_to_sg_inst (
        .binary_in(binary_num),
        .sev_seg(num)
        );


endmodule

// Code your design here
module dflipflop
  (
  input  logic d,
  input  logic clk,
  output  logic q
  
  );
  
  always_ff @(posedge clk)
    begin : flipflop
 q <= d;
end
  
  endmodule

module sync_keyboard (
    input logic clk,
    input logic kb_clk,
    input logic kb_data,
    output logic kb_clk_sync,
    output logic kb_data_sync
    );
  logic q0;
  logic q2;
// clock synchronization
    dflipflop f0
  (
    .d(kb_clk),
    .clk(clk),
    .q(q0)
  );
   dflipflop f1
  (
    .d(q0),
    .clk(clk),
    .q(kb_clk_sync)
  );
  
//    data synchronization
  
  dflipflop f2
  (
    .d(kb_data),
    .clk(clk),
    .q(q2)
  );
   dflipflop f3
  (
    .d(q2),
    .clk(clk),
    .q(kb_data_sync)
  );
  
  
  
endmodule


  
    

    
    



module convert_scancode (
    input logic clk,
    input logic rst,
    input logic edge_found,
    input logic serial_data,
    output logic valid_scan_code,
    output logic [7:0] scan_code_out
    );
  logic [10:0] shift_reg;
  logic [3:0] count;
  
  always_ff @(posedge clk)
    
    begin
      
	valid_scan_code <= 0;
    
    
      if (rst)
begin
    shift_reg <= 11'b0;
  	count<=0;
  valid_scan_code <= 0;
	scan_code_out <= 8'b0;   
end
//      ____________
      
      else
begin
   if (count==11) begin
	scan_code_out<=shift_reg[8:1];
	 	valid_scan_code <= 1;

        count <= 0;
end else begin
	if(edge_found)
     begin
       
       if (count<11)
         begin
     
          shift_reg <= {serial_data, shift_reg[10:1]};
          count<= count+1;
         end



        end
        end
end
   
    
end
      
//       ___________
      
      

endmodule

module keyboard_ctrl (
    input  logic clk,
    input  logic rst,
    input  logic valid_code,
    input  logic [7:0] scan_code_in,
    output logic [7:0] code_to_display,
    output logic [3:0] seg_en
);

  logic [1:0] count;
  logic [3:0] count_cathod = 4'b1111;;
    always_ff @(posedge clk) begin

        if (rst) begin
            code_to_display <= 8'h00;
            seg_en          <= 4'b1111;
          count<=0;
        end

        else if (valid_code) begin
           
          
          
          if (scan_code_in == 8'hF0  && count == 0 ) begin
	count <= 1;
end
          if (count == 1 ) begin
	
             case (scan_code_in)
			
            default: begin
     code_to_display <= 8'hEE;
              count <= 0;
end
            
    		8'h16: begin
        // Key 1 pressed
              code_to_display <= 8'h01;
              count <= 0;
    			end

    		8'h1E: begin
        // Key 2 pressed
              code_to_display <= 8'h02;
              count <= 0;
    			end

   			 8'h26: begin
        // Key 3 pressed
               code_to_display <= 8'h03;
               count <= 0;
   			 end
            
            
//             _________
            
                8'h25: begin
        // Key 1 pressed
                  code_to_display <= 8'h04;
                  count <= 0;
    end

    8'h2E: begin
        // Key 2 pressed
      code_to_display <= 8'h05;
      count <= 0;
    end

    8'h36: begin
        // Key 3 pressed
      code_to_display <= 8'h06;
      count <= 0;
    end

            
            8'h3D: begin
        // Key 1 pressed
                  code_to_display <= 8'h07;
              count <= 0;
    end

    8'h3E: begin
        // Key 2 pressed
      code_to_display <= 8'h08;
      count <= 0;
    end

    8'h46: begin
        // Key 3 pressed
      code_to_display <= 8'h09;
      count <= 0;
    end
  8'h45: begin
        // Key 3 pressed
      code_to_display <= 8'h00;
    count <= 0;
    end          
            
endcase
            
end
          
         
          if (count_cathod == 4'b0000) begin
	seg_en <= 4'b1111;
end else begin
	 seg_en <=  seg_en  << 1;
end
          
           
                
        end

    end

endmodule
module convert_to_binary (
    input logic [7:0] scan_code_in,
    output logic [3:0] binary_out
    );
    // Simple combinational logic using case statements (LUT)
  always_comb
    begin
        
          case (scan_code_in)
	
           default: begin
    binary_out = 4'b1111;
end 
            
    		8'h16: begin
        // Key 1 pressed
              binary_out = 4'b0001;
    			end

    		8'h1E: begin
        // Key 2 pressed
              binary_out = 4'b0010;
    			end

   			 8'h26: begin
        // Key 3 pressed
                 binary_out = 4'b0011;
   			 end
            
            
//             _________
            
                8'h25: begin
        // Key 4 pressed
                    binary_out = 4'b0100;
    end

    8'h2E: begin
        // Key 5 pressed
      binary_out = 4'b0101;
    end

    8'h36: begin
        // Key 6 pressed
      binary_out = 4'b0110;
    end
            
            8'h3D: begin
        // Key 1 pressed
                   binary_out = 4'b0111;
    end

    8'h3E: begin
        // Key 2 pressed
       binary_out = 4'b1000;
    end

    8'h46: begin
        // Key 3 pressed
      binary_out = 4'b1001;
    end
  8'h45: begin
        // Key 3 pressed
      binary_out = 4'b1010;
    end          

endcase
      
    end
  
endmodule

module binary_to_sg (
    input  logic [3:0] binary_in,
    output logic [7:0] sev_seg
);

    always_comb begin
        case (binary_in)
            4'd0: sev_seg = 8'b00111111;
            4'd1: sev_seg = 8'b00000110;
            4'd2: sev_seg = 8'b01011011;
            4'd3: sev_seg = 8'b01001111;
            4'd4: sev_seg = 8'b01100110;
            4'd5: sev_seg = 8'b01101101;
            4'd6: sev_seg = 8'b01111101;
            4'd7: sev_seg = 8'b00000111;
            4'd8: sev_seg = 8'b01111111;
            4'd9: sev_seg = 8'b01101111;
            default: sev_seg = 8'b00000000;
        endcase
    end

endmodule
