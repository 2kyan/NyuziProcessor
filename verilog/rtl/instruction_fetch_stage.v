
//
// This is currently a stub.  When multiple strands are added, this will
// need to keep 4 instruction registers (one for each strand) loaded.
// The stall_i signal will be replaced with separate flags to specify
// when each strand needs to be loaded.
//
module instruction_fetch_stage(
	input							clk,
	output [31:0]					iaddress_o,
	output [31:0]					pc_o,
	input [31:0]					idata_i,
	input                           icache_hit_i,
	output							iaccess_o,
	output [31:0]					instruction_o,
	output							instruction_ack_o,
	input							restart_request_i,
	input [31:0]					restart_address_i,
	input							instruction_request_i);
	
	reg[31:0]						program_counter_ff;
	reg[31:0]						program_counter_nxt;
	wire							fifo_empty;
	wire							fifo_will_be_full;

	assign iaddress_o = program_counter_nxt;
	assign instruction_ack_o = !fifo_empty;
	assign iaccess_o = !fifo_will_be_full;

	sync_fifo #(64, 2, 1) instruction_fifo(
		.clk(clk),
		.clear_i(restart_request_i),
		.full_o(),
		.will_be_full_o(fifo_will_be_full),
		.enqueue_i(icache_hit_i),
		.value_i({ program_counter_nxt, idata_i[7:0], idata_i[15:8], 
			idata_i[23:16], idata_i[31:24] }),
		.empty_o(fifo_empty),
		.dequeue_i(instruction_request_i && !fifo_empty),
		.value_o({ pc_o, instruction_o }));
	
	initial
	begin
		program_counter_ff = 0;
	end
	
	always @*
	begin
		if (restart_request_i)
			program_counter_nxt = restart_address_i;
		else if (!icache_hit_i)
			program_counter_nxt = program_counter_ff;
		else
			program_counter_nxt = program_counter_ff + 32'd4;
	end

	always @(posedge clk)
		program_counter_ff <= #1 program_counter_nxt;

endmodule
