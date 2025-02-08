`timescale 1ns / 1ns

module tb_cpu2;

    // Inputs
    reg clk;
    reg reset;

    // Instantiate the CPU
    cpu uut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation
    always #5 clk = ~clk; // 10ns period clock

    initial begin
        $dumpfile("tb_cpu2.vcd");
        $dumpvars(0,tb_cpu2);
        // Initialize inputs
        clk = 0;
        reset = 1;

        // Apply reset
        #10;
        reset = 0;

        // Initialize instruction memory with more instructions
        // Assume we can directly access the instruction memory for initialization in test bench
        uut.im.memory[0] = 16'b11000_000_00000001; // LI R0, 1
        uut.im.memory[1] = 16'b11000_001_00000010; // LI R1, 2
        uut.im.memory[2] = 16'b11000_010_00000100; // LI R2, 4
        uut.im.memory[3] = 16'b11000_100_00001000; // LI R4, 8
        uut.im.memory[4] = 16'b0000000001_000_001;  // ADD  R0, R1 (R0 = 1 + 2)
        uut.im.memory[5] = 16'b0000000011_010_001;  // SUB  R2, R1 (R2 = 4 - 2)
        uut.im.memory[6] = 16'b0000000011_001_100;  // SUB  R1, R4 (R2 = 2 - 8)
        uut.im.memory[7] = 16'b0000000010_000_001;  // AND  R0, R1 (R0 = 1 & 3)
        uut.im.memory[8] = 16'b0000001001_010_001;  // SAR R2, 1 (2 >>> 1)
        uut.im.memory[9] = 16'b0000001011_000_001;  // SAL R0, 1 (2 << 1)
        uut.im.memory[10] = 16'b11010_010_00000011; // SM R2, 3
        uut.im.memory[11] = 16'b11001_011_00000011; // LM R3, 3
        uut.im.memory[12] = 16'b10101_000_00000101; // JMP 5

        // Let the CPU run for some cycles to execute instructions
        #500;

        // End simulation
        $finish;
    end


    initial begin
        $monitor("Time=%0t, PC=%h, Instruction=%h, R0=%h, R1=%h, R2=%h, R3=%h, R4=%h, R5=%h, R6=%h, R7=%h", 
                 $time, uut.pc, uut.instruction, uut.rb.registers[0], uut.rb.registers[1], uut.rb.registers[2], uut.rb.registers[3], uut.rb.registers[4], uut.rb.registers[5], uut.rb.registers[6], uut.rb.registers[7]);
    end

endmodule