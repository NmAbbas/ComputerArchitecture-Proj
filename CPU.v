module register_bank (
    input wire clk,
    input wire reset,
    input wire [2:0] read_addr1,   // Address for the first read port
    input wire [2:0] read_addr2,   // Address for the second read port
    input wire [2:0] write_addr,   // Address for the write port
    input wire [7:0] write_data,   // Data to be written to the register
    input wire write_enable,       // Write enable signal
    output reg [7:0] read_data1,   // Data from the first read port
    output reg [7:0] read_data2    // Data from the second read port
);

    // Define the register bank
    reg [7:0] registers [0:7];

    // Read logic
    always @(*) begin
        read_data1 = registers[read_addr1];
        read_data2 = registers[read_addr2];
    end

    // Write logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            registers[0] <= 8'b0;
            registers[1] <= 8'b0;
            registers[2] <= 8'b0;
            registers[3] <= 8'b0;
            registers[4] <= 8'b0;
            registers[5] <= 8'b0;
            registers[6] <= 8'b0;
            registers[7] <= 8'b0;
        end else if (write_enable) begin
            registers[write_addr] <= write_data;
        end
    end

endmodule


module data_memory (
    input wire clk,               // Clock signal
    input wire [7:0] address,     // 8-bit address input, allowing access to 256 words
    input wire [7:0] write_data,  // 8-bit data to be written
    input wire mem_write,         // Memory write enable signal
    input wire mem_read,          // Memory read enable signal
    output reg [7:0] read_data    // 8-bit data output for read operation
);

    // Define the data memory as a 256x8-bit array
    reg [7:0] memory [0:255];

    // Write logic
    always @(posedge clk) begin
        if (mem_write) begin
            memory[address] <= write_data;
        end
    end

    // Read logic
    always @(*) begin
        if (mem_read) begin
            read_data = memory[address];
        end else begin
            read_data = 8'b0; // Output 0 when read is not enabled
        end
    end

endmodule





module instruction_memory (
    input wire [7:0] address,    // 8-bit address input, allowing access to 256 words
    output reg [15:0] instruction // 16-bit instruction output
);

    // Define the instruction memory as a 256x16-bit array
    reg [15:0] memory [0:255];

    // Initialize the memory with some values (if needed)
    initial begin
        // Example initialization (can be replaced with actual instructions)
        memory[0] = 16'h0000;
        memory[1] = 16'h0001;
        memory[2] = 16'h0002;
        // Continue initialization as needed
        // memory[255] = 16'h00FF;
    end

    // Read logic
    always @(*) begin
        instruction = memory[address];
    end

endmodule





module alu (
    input wire signed [7:0] a,          // 8-bit input operand a
    input wire signed [7:0] b,          // 8-bit input operand b
    output reg OF,
    output reg CF,
    output reg ZF,
    output reg SF,
    input wire [5:0] alu_ctrl,   // ALU control signal to select the operation
    output reg signed [7:0] result      // 8-bit ALU result
);


    always @(*) begin
        case (alu_ctrl) //flags of the first ones controlled in next case
            6'b000001:begin 
                {CF,result} = a + b; 
                OF = (result >8'b11111111);
                ZF = (result == 0);
                SF = result[7];
            end         // ADD
            6'b000011:begin  
                {CF,result} = a - b;
                OF = (result >8'b11111111);
                ZF = (result == 0);
                SF = result[7];
            end         // SUB
            6'b000100: begin 
                result = a | b;         
                OF = 0;
                CF =0;
                ZF = (result == 0);
                SF = result[7];
            end// OR
            6'b000101: begin 
                result = a ^ b;
                OF = 0;
                CF =0;
                ZF = (result == 0);
                SF = result[7];         
            end// XOR
            6'b000010: begin 
                result = a & b;
                OF = 0;
                CF =0;
                ZF = (result == 0);
                SF = result[7];
            end         // AND
            6'b001000: result = ~a;            // COMPLEMENT of a
            6'b001001: begin                   // SAR
                result = a >>> b;
                OF = (a[7]==result[7]);
                CF = a[0];
                ZF = (result == 0);
                SF = result[7];
            end
            6'b001011: begin                   // SAL
                result = a << b;
                OF = (a[7]!=result[7]);
                CF = a[7];
                ZF = (result == 0);
                SF = result[7];
            end
            6'b001010: begin                   // SLR
                result = a >> b;
                OF = (a[7]!=result[7]);
                CF = a[0];
                ZF = (result == 0);
                SF = result[7];
            end
            6'b001100: begin                   // SLL
                result = a << b;
                OF = (a[7]!=result[7]);
                CF = a[7];
                ZF = (result == 0);
                SF = result[7];
            end
            6'b001100: begin                   // ROL
                result = a << b;
                OF = (a[7]!=result[7]);
                CF = a[7];
                ZF = (result == 0);
                SF = result[7];
            end
            6'b001110: begin                   // ROR
                result = a >> b;
                OF = (a[7]!=result[7]);
                CF = a[7];
                ZF = (result == 0);
                SF = result[7];
            end
            6'b000110: begin                   // MOV
                result = b;
            end
            6'b010100:begin  
                result = a - b;
                OF = (result >8'b11111111);
                ZF = (result == 0);
                SF = result[7];
            end         // CMP
            default: result = 8'b00000000;  // Default case
        endcase
    end

endmodule

module cpu (
    input wire clk,
    input wire reset
);
    // Define instruction formats
    localparam ADD = 6'b000001, AND = 6'b000010, SUB = 6'b000011, OR = 6'b000100,
               XOR = 6'b000101, MOV = 6'b000110, XCHG = 6'b000111, NOT = 6'b001000,
               SAR = 6'b001001, SLR = 6'b001010, SAL = 6'b001011, SLL = 6'b001100,
               ROL = 6'b001101, ROR = 6'b001110, INC = 6'b001111, DEC = 6'b010000,
               NOP = 6'b000000, CMP = 6'b010100, JE = 6'b100000, JB = 6'b100001,
               JA = 6'b100010, JL = 6'b100011, JG = 6'b100100, JMP = 6'b101000,
               LI = 6'b110000, LM = 6'b110001, SM = 6'b110010;

    reg [7:0] pc;  // Program counter
    wire [15:0] instruction;  // Fetched instruction
    wire [5:0] alu_ctrl;
    wire [7:0] alu_result, read_data, write_data, immediate;
    reg [7:0] alu_a, alu_b;
    reg [7:0] address;
    wire [7:0] register_bank_read1_data;
    wire [7:0] register_bank_read2_data;
    reg register_bank_write_enable;
    reg [7:0] register_bank_write_data;
    reg [2:0] register_bank_write_addr;
    wire alu_of;
    wire alu_zf;
    wire alu_cf;
    wire alu_sf;
    reg OF=0;
    reg SF=0;
    reg ZF=0;
    reg CF=0;

    // Fetch instruction
    instruction_memory im (
        .address(pc),
        .instruction(instruction)
    );

    // ALU control signal based on instruction
    assign alu_ctrl = (instruction[15:12] == 4'b0000) ? instruction[11:6] : 6'b000000;
    
    // Decode and Execute
    always @(*) begin                                           //combinational stuff
        casez (instruction[15:9])
            7'b0000000: begin
                register_bank_read1_addr = instruction[5:3];
                register_bank_read2_addr = instruction[2:0];
                if(instruction[15:6]!=10'b0000000000) begin     //nop is avoided
                    alu_a = register_bank_read1_data;
                    alu_b = register_bank_read2_data;
                    register_bank_write_addr = instruction[5:3];
                    register_bank_write_data = alu_result;
                    register_bank_write_enable = 1'b1;
                    data_memory_write_en = 1'b0;
                    data_memory_read_en = 1'b0;
                end
                else begin
                    register_bank_write_enable = 1'b0;
                    data_memory_write_en = 1'b0;
                    data_memory_read_en = 1'b0;
                 end                                  //nop does nothing
            end
            7'b0000001: begin  // SAR, SLR, SAL, SLL, ROL, ROR
                register_bank_read1_addr = instruction[5:3];
                register_bank_read2_addr = instruction[2:0];
                if(instruction[15:6]!=10'b0000001111) begin    // inc is avoided
                    alu_a = register_bank_read1_data;
                    alu_b = instruction[2:0];
                    register_bank_write_addr = instruction[5:3];
                    register_bank_write_data = alu_result;
                    data_memory_write_en = 1'b0;
                    data_memory_read_en = 1'b0;
                    register_bank_write_enable = 1'b1;
                end
                else begin                                      // inc 
                    register_bank_write_addr = instruction[5:3];
                    register_bank_write_data = register_bank_read1_data+1'b1;
                    data_memory_write_en = 1'b0;
                    data_memory_read_en = 1'b0;
                    register_bank_write_enable = 1'b1;
                end
            end
            7'b0000010: begin  // DEC , CMP
                register_bank_read1_addr = instruction[5:3];
                register_bank_read2_addr = instruction[2:0];
                if(instruction[15:6]!=10'b0000010000) begin    // DEC
                    register_bank_write_addr = instruction[5:3];
                    register_bank_write_data = register_bank_read1_data-1'b1;
                    data_memory_write_en = 1'b0;
                    data_memory_read_en = 1'b0;
                    register_bank_write_enable = 1'b1;
                end
                else if (instruction[15:6]!=10'b0000010100) begin   // CMP 
                    alu_a = register_bank_read1_data;
                    alu_b = register_bank_read2_data;
                    data_memory_write_en = 1'b0;
                    data_memory_read_en = 1'b0;
                    register_bank_write_enable = 1'b0;
                end
            end
            7'b10zzzzz: begin  // JE, JB, JA, JL, JG, JMP
                data_memory_read_en = 1'b0;
                data_memory_write_en = 1'b0;
                register_bank_write_enable = 1'b0;
            end
            7'b110zzzz: begin  // LI, LM, SM
                register_bank_read1_addr = instruction[10:8];
                register_bank_read2_addr = 3'b000;
                case (instruction[15:11])
                    5'b11000: begin                 // LI
                        register_bank_write_addr = instruction[10:8];
                        register_bank_write_data = instruction[7:0];
                        data_memory_read_en = 1'b0;
                        data_memory_write_en = 1'b0;
                        register_bank_write_enable = 1'b1;
                    end  
                    5'b11001: begin                 // LM
                        data_memory_addr = instruction[7:0];
                        register_bank_write_addr = instruction[10:8];
                        register_bank_write_data = data_memory_read_data;
                        data_memory_read_en = 1'b1;
                        data_memory_write_en = 1'b0;
                        register_bank_write_enable = 1'b1;
                    end  
                    5'b11010: begin                 // SM
                        data_memory_write_data = register_bank_read1_data;
                        data_memory_addr = instruction[7:0];
                        data_memory_read_en = 1'b0;
                        data_memory_write_en = 1'b1;
                        register_bank_write_enable = 1'b0;
                    end  
                endcase
            end
        endcase
    end
    always @(posedge clk or posedge reset) begin                     //sequential stuff
        pc <= pc + 1;
        if (reset) begin
            pc <= 8'b0;
        end 
        else begin
            casez (instruction[15:9])
                7'b0000000: begin  // R-type instructions + NOP
                    if(instruction[15:6]!=10'b0000000000) begin     //nop is avoided
                        //moved to combi logic
                        OF <= alu_of;
                        CF <= alu_cf;
                        SF <= alu_sf;
                        ZF <= alu_zf; 
                    end
                                        //xchg is not possible with single cycle and this register bank
                end
                7'b0000001: begin  // SAR, SLR, SAL, SLL, ROL, ROR, INC
                    //moved to combi
                    if(instruction[15:6]!=10'b0000001111) begin    // inc is avoided
                            OF <= alu_of;
                            CF <= alu_cf;
                            SF <= alu_sf;
                            ZF <= alu_zf; 
                    end
                    else begin                                      //inc
                            OF <= (register_bank_write_data==8'b00000000);
                            CF <= (register_bank_write_data==8'b00000000);
                            SF <= register_bank_write_data[7];
                            ZF <= (register_bank_write_data==8'b00000000); 
                    end
                end
                7'b0000010: begin  //  DEC, CMP
                    if(instruction[15:6]!=10'b0000010000) begin    // DEC
                        OF <= (register_bank_write_data==8'b11111111);
                        CF <= (register_bank_write_data==8'b11111111);
                        SF <= register_bank_write_data[7];
                        ZF <= (register_bank_write_data==8'b00000000); 
                    end
                    else if (instruction[15:6]!=10'b0000010100) begin   // CMP 
                        OF <= alu_of;
                        CF <= alu_cf;
                        SF <= alu_sf;
                        ZF <= alu_zf; 
                    end
                end
                7'b10zzzzz: begin  // JE, JB, JA, JL, JG, JMP
                    case (instruction[15:11])
                        5'b10000: if (ZF == 0) begin                 // JE
                            pc <= instruction[7:0];  
                        end
                        5'b10001: if (CF == 0) begin                // JB
                            pc <= instruction[7:0];  
                        end
                        5'b10010: if ((CF == 0)&(ZF == 0)) begin    // JA
                            pc <= instruction[7:0];  
                        end
                        5'b10011: if (SF != OF) begin               // JL
                            pc <= instruction[7:0];  
                        end
                        5'b10100: if ((SF == OF)&(ZF == 0)) begin   // JG
                            pc <= instruction[7:0];  
                        end
                        5'b10101: pc <= instruction[7:0];         // JMP
                    endcase
                end
                7'b110zzzz: begin  // LI, LM, SM
                    case (instruction[15:11])
                        5'b11010: address <= instruction[11:4];  // SM
                    endcase
                end
            endcase
        end
    end

    // Immediate extraction
    assign immediate = instruction[2:0];

    // ALU instantiation
    alu alu_instance (
        .a(alu_a),
        .b(alu_b),
        .OF(alu_of),
        .CF(alu_cf),
        .ZF(alu_zf),
        .SF(alu_sf),
        .alu_ctrl(alu_ctrl),
        .result(alu_result)
    );

    reg[2:0] register_bank_read1_addr;
    reg[2:0] register_bank_read2_addr;
    
    register_bank rb (
    .clk(clk),
    .reset(reset),
    .read_addr1(register_bank_read1_addr),  
    .read_addr2(register_bank_read2_addr),
    .write_addr(register_bank_write_addr), 
    .write_data(register_bank_write_data),  
    .write_enable(register_bank_write_enable),
    .read_data1(register_bank_read1_data),
    .read_data2(register_bank_read2_data)  
    );

    // Data memory instantiation
    reg [7:0] data_memory_addr,data_memory_write_data;
    wire [7:0] data_memory_read_data;
    reg data_memory_write_en,data_memory_read_en;
    data_memory dm (
        .clk(clk),
        .address(data_memory_addr),
        .write_data(data_memory_write_data),
        .mem_write(data_memory_write_en),           // SM instruction
        .mem_read(data_memory_read_en),           // LM instruction
        .read_data(data_memory_read_data)
    );

endmodule
