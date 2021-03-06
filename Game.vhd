library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VgaUtils.all;
use work.PS2Utils.all;

entity Game is
  port (
    clk             : in std_logic; -- Pin 23, 50MHz from the onboard oscilator.
    rgb             : out std_logic_vector (2 downto 0); -- Pins 106, 105 and 104
    hsync           : out std_logic; -- Pin 101
    vsync           : out std_logic; -- Pin 103
    up              : in std_logic; -- Pin 88
    down            : in std_logic; -- Pin 89
    left            : in std_logic; -- Pin 90
    right           : in std_logic; -- Pin 91
    ps2_data        : in std_logic; -- Pin 120
    ps2_clk         : in std_logic; -- Pin 119
    seven_seg_digit : out std_logic_vector(3 downto 0); -- Pins 137,136,135,133
    seven_seg_data  : out std_logic_vector(6 downto 0) -- Pins 124,126,132,129,125,121,128
  );
end entity Game;

architecture rtl of Game is
  constant SQUARE_SIZE                  : integer := 20; -- In pixels
  constant APPLE_SIZE                   : integer := 20;
  constant SQUARE_DEFAULT_SPEED_DIVIDER : integer := 100_000;

  constant START_STATE   : integer := 0;
  constant PLAYING_STATE : integer := 1;
  constant DEAD_STATE    : integer := 2;

  signal square_speed_divider : integer := SQUARE_DEFAULT_SPEED_DIVIDER;

  signal score              : integer range 0 to 99 := 0;
  signal score_seven_seg_0  : std_logic_vector(6 downto 0);
  signal score_seven_seg_1  : std_logic_vector(6 downto 0);
  signal score_active_digit : integer range 0 to 1 := 0;
  signal score_display_clk  : std_logic;

  -- VGA Clock - 25 MHz clock derived from the 50MHz built-in clock
  signal vga_clk : std_logic;

  signal rgb_input, rgb_output : std_logic_vector(2 downto 0);
  signal vga_hsync, vga_vsync  : std_logic;
  signal hpos, vpos            : integer;

  -- The horizontal random sequence generation will be done in a different pace
  -- while the horizontal one will follow the VGA clock, leading to a greater randomness feeling
  signal rand_x_clk : std_logic;

  signal square_x           : integer range HDATA_BEGIN to HDATA_END := HDATA_BEGIN + H_HALF - SQUARE_SIZE/2;
  signal square_y           : integer range VDATA_BEGIN to VDATA_END := VDATA_BEGIN + V_HALF - SQUARE_SIZE/2;
  signal square_speed_count : integer                                := 0;

  signal apple_x : integer range HDATA_BEGIN to HDATA_END := HDATA_BEGIN + H_QUARTER;
  signal apple_y : integer range VDATA_BEGIN to VDATA_END := VDATA_BEGIN + V_QUARTER;

  signal random_x : integer;
  signal random_y : integer;

  signal is_square_out_of_bounds : boolean;
  signal should_move_square      : boolean;
  signal has_key_pressed         : std_logic;

  signal should_move_up    : std_logic;
  signal should_move_down  : std_logic;
  signal should_move_left  : std_logic;
  signal should_move_right : std_logic;
  signal should_reset      : std_logic;

  signal state : integer range 0 to 2 := START_STATE;

  signal should_draw_square : boolean;
  signal should_draw_apple  : boolean;

  component VgaController is
    port (
      clk     : in std_logic;
      rgb_in  : in std_logic_vector (2 downto 0);
      rgb_out : out std_logic_vector (2 downto 0);
      hsync   : out std_logic;
      vsync   : out std_logic;
      hpos    : out integer;
      vpos    : out integer
    );
  end component;

  component Controller is
    port (
      clk               : in std_logic;
      ps2_data          : in std_logic;
      ps2_clk           : in std_logic;
      up                : in std_logic;
      left              : in std_logic;
      right             : in std_logic;
      down              : in std_logic;
      should_move_left  : out std_logic;
      should_move_right : out std_logic;
      should_move_down  : out std_logic;
      should_move_up    : out std_logic;
      should_reset      : out std_logic
    );
  end component;

  component RandInt is
    port (
      clk         : in std_logic;
      upper_limit : in integer;
      lower_limit : in integer;
      rand_int    : out integer
    );
  end component;

  component ClockDivider is
    generic (
      divide_by : integer := 1E6
    );
    port (
      clk_in  : in std_logic;
      clk_out : out std_logic
    );
  end component;

  component ScoreDisplay is
    port (
      score       : in integer range 0 to 99;
      seven_seg_0 : out std_logic_vector(6 downto 0);
      seven_seg_1 : out std_logic_vector(6 downto 0)
    );
  end component;

begin
  vga : VgaController port map(
    clk     => vga_clk,
    rgb_in  => rgb_input,
    rgb_out => rgb_output,
    hsync   => vga_hsync,
    vsync   => vga_vsync,
    hpos    => hpos,
    vpos    => vpos
  );

  c : Controller port map(
    clk               => vga_clk,
    ps2_data          => ps2_data,
    ps2_clk           => ps2_clk,
    up                => up,
    left              => left,
    right             => right,
    down              => down,
    should_move_down  => should_move_down,
    should_move_up    => should_move_up,
    should_move_left  => should_move_left,
    should_move_right => should_move_right,
    should_reset      => should_reset
  );

  rand_x_clk_divider : ClockDivider
  generic map(
    divide_by => 5
  )
  port map(
    clk_in  => vga_clk,
    clk_out => rand_x_clk
  );

  display_clk_divider : ClockDivider
  generic map(
    divide_by => 25E2
  )
  port map(
    clk_in  => vga_clk,
    clk_out => score_display_clk
  );

  rand_x : RandInt port map(
    clk         => rand_x_clk,
    upper_limit => HDATA_END - APPLE_SIZE,
    lower_limit => HDATA_BEGIN,
    rand_int    => random_x
  );

  rand_y : RandInt port map(
    clk         => vga_clk,
    upper_limit => VDATA_END - APPLE_SIZE,
    lower_limit => VDATA_BEGIN,
    rand_int    => random_y
  );

  score_display : ScoreDisplay port map(
    score       => score,
    seven_seg_0 => score_seven_seg_0,
    seven_seg_1 => score_seven_seg_1
  );

  rgb   <= rgb_output;
  hsync <= vga_hsync;
  vsync <= vga_vsync;

  should_move_square <= square_speed_count = square_speed_divider;
  has_key_pressed    <= should_move_down xor should_move_left xor should_move_right xor should_move_up;
  is_square_out_of_bounds <= square_y <= VDATA_BEGIN or square_y >= VDATA_END - SQUARE_SIZE or square_x <= HDATA_BEGIN or square_x >= HDATA_END - SQUARE_SIZE;

  seven_seg_digit <=
    "1110" when score_active_digit = 0 else
    "1101" when score_active_digit = 1 else
    "1111";

  seven_seg_data <=
    score_seven_seg_0 when score_active_digit = 0 else
    score_seven_seg_1 when score_active_digit = 1 else
    (others => '1');

  Square(hpos, vpos, square_x, square_y, SQUARE_SIZE, should_draw_square);
  Square(hpos, vpos, apple_x, apple_y, APPLE_SIZE, should_draw_apple);

  vga_clk_divider : process (clk)
  begin
    -- We need 25MHz for the VGA so we divide the input clock by 2
    if (rising_edge(clk)) then
      vga_clk <= not vga_clk;
    end if;
  end process vga_clk_divider;

  apple_position : process (vga_clk, should_draw_square, should_draw_apple, should_reset)
  begin
    if (falling_edge(vga_clk)) then
      if (should_reset = '1') then
        -- Resetting the game
        apple_y              <= random_y;
        apple_x              <= random_x;
        square_speed_divider <= SQUARE_DEFAULT_SPEED_DIVIDER;
        score                <= 0;
      elsif (should_draw_square and should_draw_apple) then
        -- Collision between square and apple
        apple_y              <= random_y;
        apple_x              <= random_x;
        square_speed_divider <= square_speed_divider - 5000;
        score                <= score + 1;
      end if;
    end if;
  end process apple_position;

  vga_color : process (vga_clk)
  begin
    if (rising_edge(vga_clk)) then
      if (state = DEAD_STATE) then
        rgb_input <= COLOR_RED;
      elsif (state = START_STATE) then
        rgb_input <= COLOR_BLUE;
      elsif (state = PLAYING_STATE) then
        if (should_draw_square and should_draw_apple) then
          rgb_input <= COLOR_GREEN;
        elsif (should_draw_square) then
          rgb_input <= COLOR_GREEN;
        elsif (should_draw_apple) then
          rgb_input <= COLOR_RED;
        else
          rgb_input <= COLOR_BLACK;
        end if;
      end if;
    end if;
  end process vga_color;

  state_machine : process (vga_clk, is_square_out_of_bounds, has_key_pressed, should_reset)
  begin
    if (rising_edge(vga_clk)) then
      if (state = START_STATE) then
        if (has_key_pressed = '1') then
          state <= PLAYING_STATE;
        end if;
      elsif (state = PLAYING_STATE) then
        if (is_square_out_of_bounds) then
          state <= DEAD_STATE;
        elsif (should_reset = '1') then
          state <= START_STATE;
        end if;
      elsif (state = DEAD_STATE) then
        if (should_reset = '1') then
          state <= START_STATE;
        end if;
      end if;
    end if;
  end process state_machine;

  speed_divider : process (vga_clk)
  begin
    if (rising_edge(vga_clk)) then
      if (state = PLAYING_STATE) then
        if (has_key_pressed = '1') then
          if (should_move_square) then
            square_speed_count <= 0;
          else
            square_speed_count <= square_speed_count + 1;
          end if;
        else
          square_speed_count <= 0;
        end if;
      end if;
    end if;
  end process speed_divider;

  square_movement : process (vga_clk, should_reset, state)
  begin
    if (rising_edge(vga_clk)) then
      if (should_reset = '1') then
        square_x <= HDATA_BEGIN + H_HALF - SQUARE_SIZE/2;
        square_y <= VDATA_BEGIN + V_HALF - SQUARE_SIZE/2;
      elsif (should_move_square) then
        if (should_move_up = '1') then
          square_y <= square_y - 1;
        end if;

        if (should_move_down = '1') then
          square_y <= square_y + 1;
        end if;

        if (should_move_left = '1') then
          square_x <= square_x - 1;
        end if;

        if (should_move_right = '1') then
          square_x <= square_x + 1;
        end if;
      end if;
    end if;
  end process square_movement;

  seven_seg_digit_mux : process (score_display_clk)
  begin
    if (rising_edge(score_display_clk)) then
      score_active_digit <= score_active_digit + 1;
    end if;
  end process;
end architecture;