--*****************************************************************************************--
-- Company: E.S.E.O
-- Engineer: ALHAJJAR && AIOUAJ
-- 
-- Create Date:    14:44:28 02/28/2012 
-- Design Name:    
-- Module Name:    Radar - Behavioral 
-- Project Name:   démonstrateur pour radar de recul
-- Target Devices: SPARTAN 3
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--*****************************************************************************************--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.numeric_std.all;
--*****************************************************************************************--
              -----------PARTIE DECLARATION PORTS-----------
--*****************************************************************************************--
entity Radar is
generic (
constant N_TOTAL: integer :=12000
);
port(
		RAZ					:in std_logic;
		clk					:in std_logic;
		RTS					:in std_logic;
		DTR					:in std_logic;
		TXD					:in std_logic;
		DOUT					:in std_logic;
		SW		   			:in std_logic_vector(7 downto 0);
		  ----------------------
		DIN	   			:out std_logic;
		BSUSPEND				:out std_logic;
		SUSPEND 				:out std_logic;
		RI		   			:out std_logic;
		DCD					:out std_logic;
		DSR					:out std_logic;
		RXD					:out std_logic;
		CTS					:out std_logic;
		SCLK	   			:out std_logic;
		CS		   			:out std_logic;
		VBUS	   			:out std_logic;
		RST					:out std_logic;
		LED					:out std_logic_vector(7 downto 0)
);

attribute loc : string;
attribute loc of RAZ			 : SIGNAL is "M14" ;
attribute loc of clk        : SIGNAL is "T9"  ;
           ----------------------
attribute loc of DOUT       : SIGNAL is "B10" ;
attribute loc of CS         : SIGNAL is "B11" ;
attribute loc of SCLK       : SIGNAL is "A12" ;
attribute loc of din       : SIGNAL is "A13" ;
           ----------------------
attribute loc of RI         : SIGNAL is "A8"  ;
attribute loc of RST        : SIGNAL is "A7"  ;
attribute loc of BSUSPEND   : SIGNAL is "B6"  ;
attribute loc of SUSPEND    : SIGNAL is "B5"  ;
attribute loc of DCD        : SIGNAL is "B4"  ;
attribute loc of DTR        : SIGNAL is "D10" ;
attribute loc of DSR        : SIGNAL is "D8"  ;
attribute loc of TXD        : SIGNAL is "D7"  ;
attribute loc of RXD        : SIGNAL is "E7"  ;
attribute loc of RTS        : SIGNAL is "D6"  ;
attribute loc of CTS        : SIGNAL is "D5"  ;
				----------------------
attribute loc of LED        : SIGNAL is "K12,P14,L12,N14,P13,N12,P12,P11";
attribute loc of SW     	 : SIGNAL is "K13,K14,J13,J14,H13,H14,G12,F12";

end Radar;

architecture Behavioral of Radar is
--*****************************************************************************************--
              -----------PARTIE DECLARATION SIGNAUX-----------
--*****************************************************************************************--
SIGNAL EOC,EOCS,EOT,READY,WRT,DATA_READY ,SIGNAL_VOIE,EOC_RET,FM_EOC,START_ACQUISITION :std_logic;
SIGNAL EOT_RET ,FD_EOT,DIN_SIGNAL,DATA_READY_RET,FM_DATA_READY :std_logic;

SIGNAL DIN_RAM ,DOUT_RAM ,data_tab,DATAS:std_logic_vector (11 downto 0);
SIGNAL ADDR1:std_logic_vector (13 downto 0);
SIGNAL OUTPS ,OUTP_CA,INPS:std_logic_vector(7 downto 0);
SIGNAL WE1:std_logic_vector(0 downto 0);

SIGNAL ETAT : integer range 0 to 20  ;
SIGNAL COMPT_ATTENTE: integer range 0 to 219;
SIGNAL Timer: integer range 0 to 11;
SIGNAL NB_ACQUISITION :integer range 0 to 12000;
SIGNAL N_UTILISATEUR: integer range 0 to 100 :=0;
--SIGNAL COMPT120: integer range 0 to 119;

--*****************************************************************************************--
begin
--*****************************************************************************************--
              -----------PARTIE INSTANCIATION-----------
--*****************************************************************************************--
-----instanciation CAN-----

CAN:entity work.CAN(BEHAVIORAL) 

port map( 		
		CLK              => CLK,
		CS               => CS,
		SCLK             => SCLK,
		DOUT             => DOUT,
		DIN              => DIN,
		DATA             => DATAS,
		START_CONVERSION => START_ACQUISITION,
		DATA_READY       => DATA_READY,
		RAZ              => RAZ,
		VOIE             => SIGNAL_VOIE
		);
-----instanciation UART-----
MUART : entity work.Minimal_UART_CORE(principal)
 port map(
			CLOCK   => clk,
			EOC     => EOC,
			OUTP    => outps, 
			RXD     => TXD,  
			TXD     => RXD,
			EOT     => EOT,
			INP     => INPS,  
			READY   => READY,
			WR      => WRT
			);
-----instansiation de la RAM-----
RAM1:entity work.RAM(RAM_a)
PORT MAP(
		ADDRa => ADDR1,
		clka  => CLK,
		DINa  => DIN_RAM,
		DOUTa => DOUT_RAM,
		wea   => WE1
		);
--*****************************************************************************************--
RST      <= '1'      ; --Device Reset
CTS      <= 'Z'      ; --clear to send(active low)
DSR      <= 'Z'      ; --Data Set Ready control input (active low)
DCD      <= 'Z'      ; --Data Carrier Detect control input (active low)
RI       <= 'Z'      ; --Ring Indicator control input (active low)
SUSPEND  <= 'Z'      ; --This pin is driven high when the CP2102 enters the USB suspend state.
BSUSPEND <= 'Z'      ; --This pin is driven low when the CP2102 enters the USB suspend state.
---------------------
din_ram<=datas;
led<= conv_std_logic_vector (etat,8);
--*****************************************************************************************--
              -----------PARTIE DETECTION FROND MONTANT-----------
--*****************************************************************************************--				  
 ----*FM_EOT**FM_EOC**FM_DATA READY*----
p_detection_FM: process (clk)
	begin 
		 if clk'event and clk ='1' then
			EOT_RET <= EOT;
			EOC_RET <= EOC;
		 end if;
end process p_detection_FM;
      ----------------------
FD_EOT <=  EOT and (not EOT_RET );
FM_EOC <=  EOC_RET and (not EOC );

--*****************************************************************************************--
                -----------PARTIE SEQUENCEUR-----------
--*****************************************************************************************--
P_SEQUENCEUR :process(clk)
	
	begin
	
		if clk'event and clk ='1' then
			if RAZ='1' then ETAT <= 0;
			else
				case ETAT is
				
				when 0 =>
					if FM_EOC='1' then
						ETAT <= 1;
						OUTP_CA<=OUTPS;
					end if;
			--------------------------
				when 1 =>
					if OUTP_CA = "01000001" or OUTP_CA = "01100001" then 
						ETAT <= 2; 
						elsif OUTP_CA = "01010100" or OUTP_CA = "01110100" then 
							ETAT <= 9; 
						elsif OUTP_CA = "01101110" or OUTP_CA = "01001110" then 
							ETAT <= 18; 
						else
							ETAT <= 0;
					end if;
			--------------------------
				when 2 => 
				--signal_voie<='0';
--				NB_ACQUISITION<='0';
--				COMPT_ATTENTE <=0;
				ETAT <= 3;
			--------------------------
				when 3 => 
			--	start_aquisition<='1';
--			COMPT_ATTENTE <=COMPT_ATTENTE +1;
		if COMPT_ATTENTE = 219+N_UTILISATEUR then		
						
						ETAT <= 4;	
						end if;
	      --------------------------
				when 4 =>
				if data_ready='1' then	
				ETAT <= 5;
				end if;
         --------------------------
				when 5 =>
					--we1<='1';
					--start_aquisition <='0';
					--COMPT_ATTENTE <=0;
						ETAT <= 6;
			--------------------------
				when 6 =>
--					NB_ACQUISITION <=NB_ACQUISITION +1;
						ETAT <=7 ;
			--------------------------
				when 7 =>
--				wea<='0';
				ETAT <=8;
			--------------------------
				when 8 =>
				--SIGNAL_VOIE <= not(SIGNAL_VOIE);
					if NB_ACQUISITION=12000 then
						ETAT <= 0; 
						elsif NB_ACQUISITION<12000 then
						ETAT <= 3;
					end if;
	--****************************FIN ACQUISITION***********************--	
				when 9 =>
				timer <= 0 ;
--				NB_ACQUISITION<='0';			
				ETAT <= 10;
			--------------------------
				when 10 =>
--				NB_ACQUISITION <=NB_ACQUISITION +1;
--				COMPT_ATTENTE <=0;
				ETAT <= 11;	
			--------------------------	
				when 11 => 
--				compt_attente<=compt_attente +1;
				if compt_attente = 5 then
				ETAT <= 12;	
				end if;
			--------------------------
				when 12 => 
--				compt_attente <=0;
--				data_tab <= dout_ram;
				ETAT <= 13;
			--------------------------
				when 13 => 
--				INPS <= "01" & data_tab(11 downto 6);
				--wrt<='1';
				 if FD_EOT = '1' and ready='1' then 	
				ETAT <= 14;
				end if;
			------------
			when 14=>
--			timer<=timer +1;
--				if timer = 10 then
				etat <= 15;
--				end if;
			--------------
			when 15 =>
			etat<=16;
			---------------
				when 16 =>	
	   		--wrt<='1';	
--				INPS <= "01" & data_tab(5 downto 0);
					if FD_EOT = '1' and ready='1' then 	
					ETAT <= 17;
					end if;
			--------------------------
				when 17 =>
			if NB_ACQUISITION=12000 then
						ETAT <= 0; 
						elsif NB_ACQUISITION<12000 then
						ETAT <= 10;
					end if;	
			 ---------------------------				
				when 18 =>
				etat <= 19;
			 --------------------------
				when 19 => etat <=20;
		    --------------------------
				when 20 =>
				etat <=0;		

				when others =>
				
				end case;
			end if;
		end if;
	
end process P_SEQUENCEUR;

--*****************************************************************************************--
                      ----------- partie process -----------
--*****************************************************************************************--
-----process acquisition-----
P_acquisition :process(clk)
begin
if CLK'event and CLK ='1' then
	if ETAT=3 then 
		START_ACQUISITION <= '1';
	else 
		START_ACQUISITION <= '0';
	end if;
end if;
end process P_acquisition;

-----process VOIE-----
p_VOIE:process(clk)
begin
if CLK'event and CLK ='1' then
	if ETAT=2 then
		SIGNAL_VOIE <= '0';
		elsif ETAT =8 then SIGNAL_VOIE <= not(SIGNAL_VOIE);
	end if;
end if;
end process p_VOIE;

-----process envoi-----
p_envoi: process (clk)
begin 
if CLK'event and CLK ='1' then
	if ETAT =13 then
		INPS <="01"&data_tab(11 downto 6);
		elsif ETAT =14 then
		INPS <= ("01" & data_tab(5 downto 0)) ;
		
	end if;
end if;
end process p_envoi;

-----process autorisation de transmission(wrt)-----
p_wrt: process (clk)
begin
if CLK'event and CLK ='1' then
	if (ETAT=13 or ETAT=16) then
		wrt <= '1';
	else  
		wrt <= '0';
	end if; 
end if;
end process p_wrt;

-----process NB_ACQUISITION-----
P_NB_ACQUISITION : process (clk)
begin
	if clk'event and clk ='1' then
		if(ETAT=2 or ETAT=9 )then
			NB_ACQUISITION<=0;
		elsif(ETAT=6 or ETAT=10)then
			NB_ACQUISITION<=NB_ACQUISITION+1;
		end if;
	end if;
end process P_NB_ACQUISITION;

-------process_data_transmission-----
--P_DATAS : process(clk) --Lecture DATA RAM
--begin
--	if clk'event and clk ='1' then
--		if (ETAT=12)then
--			led <= DOUT_RAM(11 downto 4);
--		end if;	
--	end if;
--end process P_DATAS; 

---process ADDRESSAGE-----
P_ADDRESSAGE:process(clk)
begin
	if clk'event and clk='1' then
		if(ETAT=10 or ETAT=6) then
			ADDR1 <= conv_std_logic_vector(NB_ACQUISITION,14);
			elsif etat =1 then
			ADDR1 <= "00000000000000";
		end if;
	end if;
end process P_ADDRESSAGE;

-----process we1-----
P_autorisation_ecriture:process (clk)
begin
	if clk'event and clk ='1' then
		if (ETAT=3)then
	      we1 <= "1"; 
		elsif etat=9 then  
			we1 <= "0";
		end if;
	end if;
end process P_autorisation_ecriture;
-----process compteur_attente-----
P_compteur_attente:process (clk)
begin
	if clk'event and clk ='1' then
		if (ETAT=3 or etat=11 )then
	      compt_attente <= compt_attente+1; 
		else  
			compt_attente <= 0;
		end if;
	end if;
end process P_compteur_attente;

-----process lecture data ram-----
P_data_tab:process (clk)
begin
	if clk'event and clk ='1' then
		if (ETAT=12 )then
	      data_tab <= dout_ram; 
		end if;
	end if;
end process P_data_tab;

---processus changement frequence-----
P_changement_frequence:process (clk)
begin
	if clk'event and clk ='1' then
		if (ETAT=19 )then
	     	if OUTP_CA = "00101011" then 
					N_UTILISATEUR <=	N_UTILISATEUR + 10;
			     	elsif OUTP_CA = "00101101" then 
						N_UTILISATEUR <=	N_UTILISATEUR - 10;
				else 
				N_UTILISATEUR <= 0 ;
			end if;
		end if;
	end if;
end process P_changement_frequence;


end Behavioral;
