// rf_spinner.sv -- the F3's spinner input, as selected by jumper JP3.
//
// On the real board JP3 chooses where the JAMMA "left" and "right" lines go:
// to the joystick bits of IN.1, or to a quadrature decoder that feeds the
// analog ports IN.2 (P1) and IN.3 (P2). An optical spinner puts its two
// phases on those two wires, so in spinner mode LEFT and RIGHT are not
// directions any more -- they are the A/B channels of an encoder, and the
// board counts the edges into a 12-bit up/down position per player.
//
// The game never sees a position as such: it reads the count every frame
// and uses the difference from the last read (Arkanoid Returns, Puchi
// Carat). MAME models each port as a 12-bit wrapping counter and returns it
// as ((count & 0xF) << 12) | ((count & 0xFF0) >> 4); dial_q is that word.
//
// Decoding is the standard 4x quadrature state machine: each legal step of
// the Gray sequence 00 -> 01 -> 11 -> 10 counts one, the reverse sequence
// counts minus one, and a sample where BOTH phases changed (an impossible
// step, so the direction is unknown) is ignored rather than guessed.
//
// Inputs are already in clk's domain (hps_io's joystick words), so there is
// no synchroniser here. A source that updates both phases between two
// samples -- a USB device stepping faster than it reports -- loses those
// counts; that is a limit of the source, and is why the step is dropped.
module rf_spinner
(
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,     // JP3 = spinner
    input  logic        a,          // phase A: the player's LEFT line
    input  logic        b,          // phase B: the player's RIGHT line
    output logic [15:0] dial_q      // IN.2 / IN.3 low word
);

    logic [1:0]  prev;
    logic [11:0] count;

    wire  [1:0]  cur = {a, b};

    always_ff @(posedge clk) begin
        if (reset || !enable) begin
            prev  <= cur;
            count <= 12'd0;
        end else begin
            prev <= cur;
            // Forward is A leading B: 00 -> 10 -> 11 -> 01 -> 00.
            case ({prev, cur})
                4'b00_10, 4'b10_11, 4'b11_01, 4'b01_00: count <= count + 12'd1;
                4'b00_01, 4'b01_11, 4'b11_10, 4'b10_00: count <= count - 12'd1;
                default: ;      // no change, or both phases moved: ignore
            endcase
        end
    end

    // Off reads 0x0000, exactly as the core did before the spinner existed.
    assign dial_q = enable ? {count[3:0], 4'h0, count[11:4]} : 16'h0000;

endmodule
