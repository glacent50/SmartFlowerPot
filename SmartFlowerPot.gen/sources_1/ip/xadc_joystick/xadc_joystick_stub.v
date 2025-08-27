// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
// Date        : Wed Aug 27 12:27:26 2025
// Host        : user22-B70TV-AN5TB8W running 64-bit Ubuntu 24.04.2 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/user22/workspace_semicon/SmartFlowerPot/SmartFlowerPot.gen/sources_1/ip/xadc_joystick/xadc_joystick_stub.v
// Design      : xadc_joystick
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CORE_GENERATION_INFO = "xadc_joystick,xadc_wiz_v3_3_11,{component_name=xadc_joystick,enable_axi=false,enable_axi4stream=false,dclk_frequency=100,enable_busy=true,enable_convst=false,enable_convstclk=false,enable_dclk=true,enable_drp=true,enable_eoc=true,enable_eos=true,enable_vbram_alaram=false,enable_vccddro_alaram=false,enable_Vccint_Alaram=false,enable_Vccaux_alaram=false,enable_vccpaux_alaram=false,enable_vccpint_alaram=false,ot_alaram=false,user_temp_alaram=true,timing_mode=continuous,channel_averaging=256,sequencer_mode=on,startup_channel_selection=contineous_sequence}" *) 
module xadc_joystick(daddr_in, dclk_in, den_in, di_in, dwe_in, reset_in, 
  vauxp6, vauxn6, vauxp14, vauxn14, busy_out, channel_out, do_out, drdy_out, eoc_out, eos_out, 
  user_temp_alarm_out, alarm_out, vp_in, vn_in)
/* synthesis syn_black_box black_box_pad_pin="daddr_in[6:0],den_in,di_in[15:0],dwe_in,reset_in,vauxp6,vauxn6,vauxp14,vauxn14,busy_out,channel_out[4:0],do_out[15:0],drdy_out,eoc_out,eos_out,user_temp_alarm_out,alarm_out,vp_in,vn_in" */
/* synthesis syn_force_seq_prim="dclk_in" */;
  input [6:0]daddr_in;
  input dclk_in /* synthesis syn_isclock = 1 */;
  input den_in;
  input [15:0]di_in;
  input dwe_in;
  input reset_in;
  input vauxp6;
  input vauxn6;
  input vauxp14;
  input vauxn14;
  output busy_out;
  output [4:0]channel_out;
  output [15:0]do_out;
  output drdy_out;
  output eoc_out;
  output eos_out;
  output user_temp_alarm_out;
  output alarm_out;
  input vp_in;
  input vn_in;
endmodule
