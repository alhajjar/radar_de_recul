--*****************************************************************************************--
-- Company: E.S.E.O
-- Engineer: ALHAJJAR && AIOUAJ
-- 
-- Create Date:    14:58:36 02/28/2012 
-- Design Name:    
-- Module Name:    CAN - Behavioral 
-- Project Name:   d�monstrateur pour radar de recul
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--*****************************************************************************************--
              -----------PARTIE DECLARATION PORTS-----------
--*****************************************************************************************--

entity CAN is 
    Port ( 
           DIN  : OUT STD_LOGIC;
			  DOUT : IN STD_LOGIC;
			  START_CONVERSION:in STD_LOGIC;
			  CS: OUT STD_LOGIC;
			  CLK :in STD_LOGIC;
           DATA_READY : out STD_LOGIC;
			  RAZ  : in STD_LOGIC;
			  SCLK : out STD_LOGIC;
			  DATA :OUT STD_LOGIC_VECTOR (11 downto 0);
			  VOIE: in STD_LOGIC
            );
end CAN;

architecture Behavioral of CAN is

--*****************************************************************************************--
              -----------PARTIE DECLARATION SIGNAUX-----------
--*****************************************************************************************--
signal COMPTEUR_SCLK : integer range 0 to 18;
signal AS,START_CONVERSION_FM: std_logic;
signal cpt10 : integer range 0 to 9;

begin
--*****************************************************************************************--
              -----------PARTIE DETECTION FROND MONTANT-----------
--*****************************************************************************************--	
P_START_CONVERSION :process (CLK)
	begin 
    if rising_edge(CLK) then
        AS <=START_CONVERSION;
    end if;
	 --DIN <='0';
	end process P_START_CONVERSION;

START_CONVERSION_FM<=((START_CONVERSION and not AS));
--*****************************************************************************************--
                      ----------- partie process -----------
--*****************************************************************************************--
-----------PROCESS COMPTEUR_SCLK-----------
P_COMPTEUR_SCLK: process (CLK)
begin
 if CLK'event and CLK ='1' then
  if START_CONVERSION_FM = '1' then
   COMPTEUR_SCLK <= 1; 
   elsif cpt10=9 then
    if COMPTEUR_SCLK < 18 then 
    COMPTEUR_SCLK<=COMPTEUR_SCLK+1;
     ELSE COMPTEUR_SCLK <= 0;
    end if;
  end if;
 end if; 
end process P_COMPTEUR_SCLK;

-----------process_compteur_10-----------
P_CPT10: process(CLK)
begin
    if CLK'event and CLK ='1' then
        if START_CONVERSION_FM = '1' then
				CPT10 <= 0;
			elsif CPT10 = 9 then
				CPT10 <= 0;
			else
				CPT10 <= CPT10 + 1;
        end if;
    end if;
end process P_CPT10;
-----------PROCESS voie-----------
P_voie :process (CLK)
begin 
	if CLK'event and CLK ='1' then
		if START_CONVERSION_FM = '1' then
        din<=voie;		
		end if;
	end if;
end process P_voie;
-----------PROCESS CS-----------
P_CS :process (CLK)
begin 
 if CLK'event and CLK ='1' then
  if START_CONVERSION_FM = '1' then 
         CS<= '0'; 
  elsif COMPTEUR_SCLK=18 then 
   CS<='1';
  end if;
 end if;
end process P_CS;
-----------PROCESS data_ready-----------
P_DATA_READY :process (CLK)
begin 
 if CLK'event and CLK ='1' then
  if START_CONVERSION_FM = '1' then
   DATA_READY <= '0';  
  elsif COMPTEUR_SCLK=18 then 
   DATA_READY <= '1'; 
  end if;
 end if;
end process P_DATA_READY;

-----------PROCESS CLK_CAN-----------
--chaque 4 cycle de clock du fpga correspond a 1 cycle de clock du can alors l� on divise notre fr�quence par 4 
--car la frequence max du can =18 mHz et celle du fpga=50mHZ
P_SCLK : process (CLK)
begin 
     if CLK'event and CLK ='1' then 
            if cpt10 < 5 then
                SCLK <='1';
            else
                SCLK <='0';
            end if;
    end if;  
end process P_SCLK;

-----------remplissage data-----------
P_DATA_IN : process(CLK)
begin
    if CLK'event and CLK ='1' then
		  if cpt10=2 then
			  case COMPTEUR_SCLK is
				  when 5  => DATA(11)  <= DOUT;
				  when 6  => DATA(10)  <= DOUT;
				  when 7  => DATA(9)   <= DOUT;
				  when 8  => DATA(8)   <= DOUT;
				  when 9  => DATA(7)   <= DOUT;
				  when 10 => DATA(6)   <= DOUT;
				  when 11 => DATA(5)   <= DOUT;
				  when 12 => DATA(4)   <= DOUT;
				  when 13 => DATA(3)   <= DOUT;
				  when 14 => DATA(2)   <= DOUT;
				  when 15 => DATA(1)   <= DOUT;
				  when 16 => DATA(0)   <= DOUT;
				  when others =>
				end case;
			  end if; 
    end if;
end process P_DATA_IN ;

end Behavioral;

