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
//
// Mouse: a mouse on the MiSTer can drive the same counter directly. Each
// mouse packet (mstb, one clk pulse) adds its delta, scaled by msens, to
// the count. The result the game reads is exactly what an encoder turned
// by that many steps would have produced, without squeezing the motion
// through two wires first -- so no step is ever dropped, however fast the
// mouse moves. The counter carries 3 fractional bits so a mouse count can
// be worth less than one step; the game only sees the 12 whole-step bits.
//   msens 0: 1/4 step per mouse count   2: 1/2
//         1: 1/8                        3: 1
module rf_spinner
(
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,     // JP3 = spinner
    input  logic        a,          // phase A: the player's LEFT line
    input  logic        b,          // phase B: the player's RIGHT line
    input  logic        mstb,       // mouse packet arrived (gated by the caller)
    input  logic signed [9:0] mdelta,   // mouse counts, + = forward
    input  logic  [1:0] msens,
    output logic [15:0] dial_q      // IN.2 / IN.3 low word
);

    logic [1:0]  prev;
    logic [14:0] count;             // [14:3] whole steps, [2:0] eighths

    wire  [1:0]  cur = {a, b};

    // One encoder step is 8 eighths.
    logic signed [14:0] qstep;
    always_comb begin
        // Forward is A leading B: 00 -> 10 -> 11 -> 01 -> 00.
        case ({prev, cur})
            4'b00_10, 4'b10_11, 4'b11_01, 4'b01_00: qstep =  15'sd8;
            4'b00_01, 4'b01_11, 4'b11_10, 4'b10_00: qstep = -15'sd8;
            default:                                qstep =  15'sd0;   // no change, or both moved
        endcase
    end

    // Mouse counts in eighths of a step. |mdelta| <= 512, x8 = 4096: fits.
    wire signed [14:0] md = mdelta;     // sign-extended
    logic signed [14:0] mstep;
    always_comb begin
        if (!mstb) mstep = 15'sd0;
        else case (msens)
            2'd0: mstep = md <<< 1;     // 1/4
            2'd1: mstep = md;           // 1/8
            2'd2: mstep = md <<< 2;     // 1/2
            2'd3: mstep = md <<< 3;     // 1
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset || !enable) begin
            prev  <= cur;
            count <= 15'd0;
        end else begin
            prev  <= cur;
            count <= count + qstep + mstep;
        end
    end

    // Off reads 0x0000, exactly as the core did before the spinner existed.
    wire [11:0] whole = count[14:3];
    assign dial_q = enable ? {whole[3:0], 4'h0, whole[11:4]} : 16'h0000;

endmodule
