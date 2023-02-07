--  https://github.com/ScottishRoss/Countries-SQL-Oracle

CREATE TABLE country (
  id number        generated always as identity (start with 1) primary key not null,
  iso varchar2(2) NOT NULL,
  name varchar(80) NOT NULL,
  formatted_name varchar2(80) NOT NULL,
  iso3 varchar2(3),
  numcode number,
  phonecode number
)  ;
--
-- Dumping data for table `country`
--

INSERT INTO country (iso, name, formatted_name, iso3, numcode, phonecode)
select 'AF' iso, 'AFGHANISTAN' name, 'Afghanistan' formatted_name, 'AFG' iso3, 4 numcode, 93 phonecode from dual union all
select 'AL', 'ALBANIA', 'Albania', 'ALB', 8, 355 from dual union all
select 'DZ', 'ALGERIA', 'Algeria', 'DZA', 12, 213 from dual union all
select 'AS', 'AMERICAN SAMOA', 'American Samoa', 'ASM', 16, 1684 from dual union all
select 'AD', 'ANDORRA', 'Andorra', 'AND', 20, 376 from dual union all
select 'AO', 'ANGOLA', 'Angola', 'AGO', 24, 244 from dual union all
select 'AI', 'ANGUILLA', 'Anguilla', 'AIA', 660, 1264 from dual union all
select 'AQ', 'ANTARCTICA', 'Antarctica', NULL, NULL, 0 from dual union all
select 'AG', 'ANTIGUA AND BARBUDA', 'Antigua and Barbuda', 'ATG', 28, 1268 from dual union all
select 'AR', 'ARGENTINA', 'Argentina', 'ARG', 32, 54 from dual union all
select 'AM', 'ARMENIA', 'Armenia', 'ARM', 51, 374 from dual union all
select 'AW', 'ARUBA', 'Aruba', 'ABW', 533, 297 from dual union all
select 'AU', 'AUSTRALIA', 'Australia', 'AUS', 36, 61 from dual union all
select 'AT', 'AUSTRIA', 'Austria', 'AUT', 40, 43 from dual union all
select 'AZ', 'AZERBAIJAN', 'Azerbaijan', 'AZE', 31, 994 from dual union all
select 'BS', 'BAHAMAS', 'Bahamas', 'BHS', 44, 1242 from dual union all
select 'BH', 'BAHRAIN', 'Bahrain', 'BHR', 48, 973 from dual union all
select 'BD', 'BANGLADESH', 'Bangladesh', 'BGD', 50, 880 from dual union all
select 'BB', 'BARBADOS', 'Barbados', 'BRB', 52, 1246 from dual union all
select 'BY', 'BELARUS', 'Belarus', 'BLR', 112, 375 from dual union all
select 'BE', 'BELGIUM', 'Belgium', 'BEL', 56, 32 from dual union all
select 'BZ', 'BELIZE', 'Belize', 'BLZ', 84, 501 from dual union all
select 'BJ', 'BENIN', 'Benin', 'BEN', 204, 229 from dual union all
select 'BM', 'BERMUDA', 'Bermuda', 'BMU', 60, 1441 from dual union all
select 'BT', 'BHUTAN', 'Bhutan', 'BTN', 64, 975 from dual union all
select 'BO', 'BOLIVIA', 'Bolivia', 'BOL', 68, 591 from dual union all
select 'BA', 'BOSNIA AND HERZEGOVINA', 'Bosnia and Herzegovina', 'BIH', 70, 387 from dual union all
select 'BW', 'BOTSWANA', 'Botswana', 'BWA', 72, 267 from dual union all
select 'BV', 'BOUVET ISLAND', 'Bouvet Island', NULL, NULL, 0 from dual union all
select 'BR', 'BRAZIL', 'Brazil', 'BRA', 76, 55 from dual union all
select 'IO', 'BRITISH INDIAN OCEAN TERRITORY', 'British Indian Ocean Territory', NULL, NULL, 246 from dual union all
select 'BN', 'BRUNEI DARUSSALAM', 'Brunei Darussalam', 'BRN', 96, 673 from dual union all
select 'BG', 'BULGARIA', 'Bulgaria', 'BGR', 100, 359 from dual union all
select 'BF', 'BURKINA FASO', 'Burkina Faso', 'BFA', 854, 226 from dual union all
select 'BI', 'BURUNDI', 'Burundi', 'BDI', 108, 257 from dual union all
select 'KH', 'CAMBODIA', 'Cambodia', 'KHM', 116, 855 from dual union all
select 'CM', 'CAMEROON', 'Cameroon', 'CMR', 120, 237 from dual union all
select 'CA', 'CANADA', 'Canada', 'CAN', 124, 1 from dual union all
select 'CV', 'CAPE VERDE', 'Cape Verde', 'CPV', 132, 238 from dual union all
select 'KY', 'CAYMAN ISLANDS', 'Cayman Islands', 'CYM', 136, 1345 from dual union all
select 'CF', 'CENTRAL AFRICAN REPUBLIC', 'Central African Republic', 'CAF', 140, 236 from dual union all
select 'TD', 'CHAD', 'Chad', 'TCD', 148, 235 from dual union all
select 'CL', 'CHILE', 'Chile', 'CHL', 152, 56 from dual union all
select 'CN', 'CHINA', 'China', 'CHN', 156, 86 from dual union all
select 'CX', 'CHRISTMAS ISLAND', 'Christmas Island', NULL, NULL, 61 from dual union all
select 'CC', 'COCOS (KEELING) ISLANDS', 'Cocos (Keeling) Islands', NULL, NULL, 672 from dual union all
select 'CO', 'COLOMBIA', 'Colombia', 'COL', 170, 57 from dual union all
select 'KM', 'COMOROS', 'Comoros', 'COM', 174, 269 from dual union all
select 'CG', 'CONGO', 'Congo', 'COG', 178, 242 from dual union all
select 'CD', 'CONGO, THE DEMOCRATIC REPUBLIC OF THE', 'Congo, the Democratic Republic of the', 'COD', 180, 242 from dual union all
select 'CK', 'COOK ISLANDS', 'Cook Islands', 'COK', 184, 682 from dual union all
select 'CR', 'COSTA RICA', 'Costa Rica', 'CRI', 188, 506 from dual union all
select 'CI', 'COTE D''IVOIRE', 'Cote D''Ivoire', 'CIV', 384, 225 from dual union all
select 'HR', 'CROATIA', 'Croatia', 'HRV', 191, 385 from dual union all
select 'CU', 'CUBA', 'Cuba', 'CUB', 192, 53 from dual union all
select 'CY', 'CYPRUS', 'Cyprus', 'CYP', 196, 357 from dual union all
select 'CZ', 'CZECH REPUBLIC', 'Czech Republic', 'CZE', 203, 420 from dual union all
select 'DK', 'DENMARK', 'Denmark', 'DNK', 208, 45 from dual union all
select 'DJ', 'DJIBOUTI', 'Djibouti', 'DJI', 262, 253 from dual union all
select 'DM', 'DOMINICA', 'Dominica', 'DMA', 212, 1767 from dual union all
select 'DO', 'DOMINICAN REPUBLIC', 'Dominican Republic', 'DOM', 214, 1809 from dual union all
select 'EC', 'ECUADOR', 'Ecuador', 'ECU', 218, 593 from dual union all
select 'EG', 'EGYPT', 'Egypt', 'EGY', 818, 20 from dual union all
select 'SV', 'EL SALVADOR', 'El Salvador', 'SLV', 222, 503 from dual union all
select 'GQ', 'EQUATORIAL GUINEA', 'Equatorial Guinea', 'GNQ', 226, 240 from dual union all
select 'ER', 'ERITREA', 'Eritrea', 'ERI', 232, 291 from dual union all
select 'EE', 'ESTONIA', 'Estonia', 'EST', 233, 372 from dual union all
select 'ET', 'ETHIOPIA', 'Ethiopia', 'ETH', 231, 251 from dual union all
select 'FK', 'FALKLAND ISLANDS (MALVINAS)', 'Falkland Islands (Malvinas)', 'FLK', 238, 500 from dual union all
select 'FO', 'FAROE ISLANDS', 'Faroe Islands', 'FRO', 234, 298 from dual union all
select 'FJ', 'FIJI', 'Fiji', 'FJI', 242, 679 from dual union all
select 'FI', 'FINLAND', 'Finland', 'FIN', 246, 358 from dual union all
select 'FR', 'FRANCE', 'France', 'FRA', 250, 33 from dual union all
select 'GF', 'FRENCH GUIANA', 'French Guiana', 'GUF', 254, 594 from dual union all
select 'PF', 'FRENCH POLYNESIA', 'French Polynesia', 'PYF', 258, 689 from dual union all
select 'TF', 'FRENCH SOUTHERN TERRITORIES', 'French Southern Territories', NULL, NULL, 0 from dual union all
select 'GA', 'GABON', 'Gabon', 'GAB', 266, 241 from dual union all
select 'GM', 'GAMBIA', 'Gambia', 'GMB', 270, 220 from dual union all
select 'GE', 'GEORGIA', 'Georgia', 'GEO', 268, 995 from dual union all
select 'DE', 'GERMANY', 'Germany', 'DEU', 276, 49 from dual union all
select 'GH', 'GHANA', 'Ghana', 'GHA', 288, 233 from dual union all
select 'GI', 'GIBRALTAR', 'Gibraltar', 'GIB', 292, 350 from dual union all
select 'GR', 'GREECE', 'Greece', 'GRC', 300, 30 from dual union all
select 'GL', 'GREENLAND', 'Greenland', 'GRL', 304, 299 from dual union all
select 'GD', 'GRENADA', 'Grenada', 'GRD', 308, 1473 from dual union all
select 'GP', 'GUADELOUPE', 'Guadeloupe', 'GLP', 312, 590 from dual union all
select 'GU', 'GUAM', 'Guam', 'GUM', 316, 1671 from dual union all
select 'GT', 'GUATEMALA', 'Guatemala', 'GTM', 320, 502 from dual union all
select 'GN', 'GUINEA', 'Guinea', 'GIN', 324, 224 from dual union all
select 'GW', 'GUINEA-BISSAU', 'Guinea-Bissau', 'GNB', 624, 245 from dual union all
select 'GY', 'GUYANA', 'Guyana', 'GUY', 328, 592 from dual union all
select 'HT', 'HAITI', 'Haiti', 'HTI', 332, 509 from dual union all
select 'HM', 'HEARD ISLAND AND MCDONALD ISLANDS', 'Heard Island and Mcdonald Islands', NULL, NULL, 0 from dual union all
select 'VA', 'HOLY SEE (VATICAN CITY STATE)', 'Holy See (Vatican City State)', 'VAT', 336, 39 from dual union all
select 'HN', 'HONDURAS', 'Honduras', 'HND', 340, 504 from dual union all
select 'HK', 'HONG KONG', 'Hong Kong', 'HKG', 344, 852 from dual union all
select 'HU', 'HUNGARY', 'Hungary', 'HUN', 348, 36 from dual union all
select 'IS', 'ICELAND', 'Iceland', 'ISL', 352, 354 from dual union all
select 'IN', 'INDIA', 'India', 'IND', 356, 91 from dual union all
select 'ID', 'INDONESIA', 'Indonesia', 'IDN', 360, 62 from dual union all
select 'IR', 'IRAN, ISLAMIC REPUBLIC OF', 'Iran, Islamic Republic of', 'IRN', 364, 98 from dual union all
select 'IQ', 'IRAQ', 'Iraq', 'IRQ', 368, 964 from dual union all
select 'IE', 'IRELAND', 'Ireland', 'IRL', 372, 353 from dual union all
select 'IL', 'ISRAEL', 'Israel', 'ISR', 376, 972 from dual union all
select 'IT', 'ITALY', 'Italy', 'ITA', 380, 39 from dual union all
select 'JM', 'JAMAICA', 'Jamaica', 'JAM', 388, 1876 from dual union all
select 'JP', 'JAPAN', 'Japan', 'JPN', 392, 81 from dual union all
select 'JO', 'JORDAN', 'Jordan', 'JOR', 400, 962 from dual union all
select 'KZ', 'KAZAKHSTAN', 'Kazakhstan', 'KAZ', 398, 7 from dual union all
select 'KE', 'KENYA', 'Kenya', 'KEN', 404, 254 from dual union all
select 'KI', 'KIRIBATI', 'Kiribati', 'KIR', 296, 686 from dual union all
select 'KP', 'KOREA, DEMOCRATIC PEOPLE''S REPUBLIC OF', 'Korea, Democratic People''s Republic of', 'PRK', 408, 850 from dual union all
select 'KR', 'KOREA, REPUBLIC OF', 'Korea, Republic of', 'KOR', 410, 82 from dual union all
select 'KW', 'KUWAIT', 'Kuwait', 'KWT', 414, 965 from dual union all
select 'KG', 'KYRGYZSTAN', 'Kyrgyzstan', 'KGZ', 417, 996 from dual union all
select 'LA', 'LAO PEOPLE''S DEMOCRATIC REPUBLIC', 'Lao People''s Democratic Republic', 'LAO', 418, 856 from dual union all
select 'LV', 'LATVIA', 'Latvia', 'LVA', 428, 371 from dual union all
select 'LB', 'LEBANON', 'Lebanon', 'LBN', 422, 961 from dual union all
select 'LS', 'LESOTHO', 'Lesotho', 'LSO', 426, 266 from dual union all
select 'LR', 'LIBERIA', 'Liberia', 'LBR', 430, 231 from dual union all
select 'LY', 'LIBYAN ARAB JAMAHIRIYA', 'Libyan Arab Jamahiriya', 'LBY', 434, 218 from dual union all
select 'LI', 'LIECHTENSTEIN', 'Liechtenstein', 'LIE', 438, 423 from dual union all
select 'LT', 'LITHUANIA', 'Lithuania', 'LTU', 440, 370 from dual union all
select 'LU', 'LUXEMBOURG', 'Luxembourg', 'LUX', 442, 352 from dual union all
select 'MO', 'MACAO', 'Macao', 'MAC', 446, 853 from dual union all
select 'MK', 'MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF', 'Macedonia, the Former Yugoslav Republic of', 'MKD', 807, 389 from dual union all
select 'MG', 'MADAGASCAR', 'Madagascar', 'MDG', 450, 261 from dual union all
select 'MW', 'MALAWI', 'Malawi', 'MWI', 454, 265 from dual union all
select 'MY', 'MALAYSIA', 'Malaysia', 'MYS', 458, 60 from dual union all
select 'MV', 'MALDIVES', 'Maldives', 'MDV', 462, 960 from dual union all
select 'ML', 'MALI', 'Mali', 'MLI', 466, 223 from dual union all
select 'MT', 'MALTA', 'Malta', 'MLT', 470, 356 from dual union all
select 'MH', 'MARSHALL ISLANDS', 'Marshall Islands', 'MHL', 584, 692 from dual union all
select 'MQ', 'MARTINIQUE', 'Martinique', 'MTQ', 474, 596 from dual union all
select 'MR', 'MAURITANIA', 'Mauritania', 'MRT', 478, 222 from dual union all
select 'MU', 'MAURITIUS', 'Mauritius', 'MUS', 480, 230 from dual union all
select 'YT', 'MAYOTTE', 'Mayotte', NULL, NULL, 269 from dual union all
select 'MX', 'MEXICO', 'Mexico', 'MEX', 484, 52 from dual union all
select 'FM', 'MICRONESIA, FEDERATED STATES OF', 'Micronesia, Federated States of', 'FSM', 583, 691 from dual union all
select 'MD', 'MOLDOVA, REPUBLIC OF', 'Moldova, Republic of', 'MDA', 498, 373 from dual union all
select 'MC', 'MONACO', 'Monaco', 'MCO', 492, 377 from dual union all
select 'MN', 'MONGOLIA', 'Mongolia', 'MNG', 496, 976 from dual union all
select 'MS', 'MONTSERRAT', 'Montserrat', 'MSR', 500, 1664 from dual union all
select 'MA', 'MOROCCO', 'Morocco', 'MAR', 504, 212 from dual union all
select 'MZ', 'MOZAMBIQUE', 'Mozambique', 'MOZ', 508, 258 from dual union all
select 'MM', 'MYANMAR', 'Myanmar', 'MMR', 104, 95 from dual union all
select 'NA', 'NAMIBIA', 'Namibia', 'NAM', 516, 264 from dual union all
select 'NR', 'NAURU', 'Nauru', 'NRU', 520, 674 from dual union all
select 'NP', 'NEPAL', 'Nepal', 'NPL', 524, 977 from dual union all
select 'NL', 'NETHERLANDS', 'Netherlands', 'NLD', 528, 31 from dual union all
select 'AN', 'NETHERLANDS ANTILLES', 'Netherlands Antilles', 'ANT', 530, 599 from dual union all
select 'NC', 'NEW CALEDONIA', 'New Caledonia', 'NCL', 540, 687 from dual union all
select 'NZ', 'NEW ZEALAND', 'New Zealand', 'NZL', 554, 64 from dual union all
select 'NI', 'NICARAGUA', 'Nicaragua', 'NIC', 558, 505 from dual union all
select 'NE', 'NIGER', 'Niger', 'NER', 562, 227 from dual union all
select 'NG', 'NIGERIA', 'Nigeria', 'NGA', 566, 234 from dual union all
select 'NU', 'NIUE', 'Niue', 'NIU', 570, 683 from dual union all
select 'NF', 'NORFOLK ISLAND', 'Norfolk Island', 'NFK', 574, 672 from dual union all
select 'MP', 'NORTHERN MARIANA ISLANDS', 'Northern Mariana Islands', 'MNP', 580, 1670 from dual union all
select 'NO', 'NORWAY', 'Norway', 'NOR', 578, 47 from dual union all
select 'OM', 'OMAN', 'Oman', 'OMN', 512, 968 from dual union all
select 'PK', 'PAKISTAN', 'Pakistan', 'PAK', 586, 92 from dual union all
select 'PW', 'PALAU', 'Palau', 'PLW', 585, 680 from dual union all
select 'PS', 'PALESTINIAN TERRITORY, OCCUPIED', 'Palestinian Territory, Occupied', NULL, NULL, 970 from dual union all
select 'PA', 'PANAMA', 'Panama', 'PAN', 591, 507 from dual union all
select 'PG', 'PAPUA NEW GUINEA', 'Papua New Guinea', 'PNG', 598, 675 from dual union all
select 'PY', 'PARAGUAY', 'Paraguay', 'PRY', 600, 595 from dual union all
select 'PE', 'PERU', 'Peru', 'PER', 604, 51 from dual union all
select 'PH', 'PHILIPPINES', 'Philippines', 'PHL', 608, 63 from dual union all
select 'PN', 'PITCAIRN', 'Pitcairn', 'PCN', 612, 0 from dual union all
select 'PL', 'POLAND', 'Poland', 'POL', 616, 48 from dual union all
select 'PT', 'PORTUGAL', 'Portugal', 'PRT', 620, 351 from dual union all
select 'PR', 'PUERTO RICO', 'Puerto Rico', 'PRI', 630, 1787 from dual union all
select 'QA', 'QATAR', 'Qatar', 'QAT', 634, 974 from dual union all
select 'RE', 'REUNION', 'Reunion', 'REU', 638, 262 from dual union all
select 'RO', 'ROMANIA', 'Romania', 'ROM', 642, 40 from dual union all
select 'RU', 'RUSSIAN FEDERATION', 'Russian Federation', 'RUS', 643, 70 from dual union all
select 'RW', 'RWANDA', 'Rwanda', 'RWA', 646, 250 from dual union all
select 'SH', 'SAINT HELENA', 'Saint Helena', 'SHN', 654, 290 from dual union all
select 'KN', 'SAINT KITTS AND NEVIS', 'Saint Kitts and Nevis', 'KNA', 659, 1869 from dual union all
select 'LC', 'SAINT LUCIA', 'Saint Lucia', 'LCA', 662, 1758 from dual union all
select 'PM', 'SAINT PIERRE AND MIQUELON', 'Saint Pierre and Miquelon', 'SPM', 666, 508 from dual union all
select 'VC', 'SAINT VINCENT AND THE GRENADINES', 'Saint Vincent and the Grenadines', 'VCT', 670, 1784 from dual union all
select 'WS', 'SAMOA', 'Samoa', 'WSM', 882, 684 from dual union all
select 'SM', 'SAN MARINO', 'San Marino', 'SMR', 674, 378 from dual union all
select 'ST', 'SAO TOME AND PRINCIPE', 'Sao Tome and Principe', 'STP', 678, 239 from dual union all
select 'SA', 'SAUDI ARABIA', 'Saudi Arabia', 'SAU', 682, 966 from dual union all
select 'SN', 'SENEGAL', 'Senegal', 'SEN', 686, 221 from dual union all
select 'CS', 'SERBIA AND MONTENEGRO', 'Serbia and Montenegro', NULL, NULL, 381 from dual union all
select 'SC', 'SEYCHELLES', 'Seychelles', 'SYC', 690, 248 from dual union all
select 'SL', 'SIERRA LEONE', 'Sierra Leone', 'SLE', 694, 232 from dual union all
select 'SG', 'SINGAPORE', 'Singapore', 'SGP', 702, 65 from dual union all
select 'SK', 'SLOVAKIA', 'Slovakia', 'SVK', 703, 421 from dual union all
select 'SI', 'SLOVENIA', 'Slovenia', 'SVN', 705, 386 from dual union all
select 'SB', 'SOLOMON ISLANDS', 'Solomon Islands', 'SLB', 90, 677 from dual union all
select 'SO', 'SOMALIA', 'Somalia', 'SOM', 706, 252 from dual union all
select 'ZA', 'SOUTH AFRICA', 'South Africa', 'ZAF', 710, 27 from dual union all
select 'GS', 'SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS', 'South Georgia and the South Sandwich Islands', NULL, NULL, 0 from dual union all
select 'ES', 'SPAIN', 'Spain', 'ESP', 724, 34 from dual union all
select 'LK', 'SRI LANKA', 'Sri Lanka', 'LKA', 144, 94 from dual union all
select 'SD', 'SUDAN', 'Sudan', 'SDN', 736, 249 from dual union all
select 'SR', 'SURINAME', 'Suriname', 'SUR', 740, 597 from dual union all
select 'SJ', 'SVALBARD AND JAN MAYEN', 'Svalbard and Jan Mayen', 'SJM', 744, 47 from dual union all
select 'SZ', 'SWAZILAND', 'Swaziland', 'SWZ', 748, 268 from dual union all
select 'SE', 'SWEDEN', 'Sweden', 'SWE', 752, 46 from dual union all
select 'CH', 'SWITZERLAND', 'Switzerland', 'CHE', 756, 41 from dual union all
select 'SY', 'SYRIAN ARAB REPUBLIC', 'Syrian Arab Republic', 'SYR', 760, 963 from dual union all
select 'TW', 'TAIWAN, PROVINCE OF CHINA', 'Taiwan, Province of China', 'TWN', 158, 886 from dual union all
select 'TJ', 'TAJIKISTAN', 'Tajikistan', 'TJK', 762, 992 from dual union all
select 'TZ', 'TANZANIA, UNITED REPUBLIC OF', 'Tanzania, United Republic of', 'TZA', 834, 255 from dual union all
select 'TH', 'THAILAND', 'Thailand', 'THA', 764, 66 from dual union all
select 'TL', 'TIMOR-LESTE', 'Timor-Leste', NULL, NULL, 670 from dual union all
select 'TG', 'TOGO', 'Togo', 'TGO', 768, 228 from dual union all
select 'TK', 'TOKELAU', 'Tokelau', 'TKL', 772, 690 from dual union all
select 'TO', 'TONGA', 'Tonga', 'TON', 776, 676 from dual union all
select 'TT', 'TRINIDAD AND TOBAGO', 'Trinidad and Tobago', 'TTO', 780, 1868 from dual union all
select 'TN', 'TUNISIA', 'Tunisia', 'TUN', 788, 216 from dual union all
select 'TR', 'TURKEY', 'Turkey', 'TUR', 792, 90 from dual union all
select 'TM', 'TURKMENISTAN', 'Turkmenistan', 'TKM', 795, 7370 from dual union all
select 'TC', 'TURKS AND CAICOS ISLANDS', 'Turks and Caicos Islands', 'TCA', 796, 1649 from dual union all
select 'TV', 'TUVALU', 'Tuvalu', 'TUV', 798, 688 from dual union all
select 'UG', 'UGANDA', 'Uganda', 'UGA', 800, 256 from dual union all
select 'UA', 'UKRAINE', 'Ukraine', 'UKR', 804, 380 from dual union all
select 'AE', 'UNITED ARAB EMIRATES', 'United Arab Emirates', 'ARE', 784, 971 from dual union all
select 'GB', 'UNITED KINGDOM', 'United Kingdom', 'GBR', 826, 44 from dual union all
select 'US', 'UNITED STATES', 'United States', 'USA', 840, 1 from dual union all
select 'UM', 'UNITED STATES MINOR OUTLYING ISLANDS', 'United States Minor Outlying Islands', NULL, NULL, 1 from dual union all
select 'UY', 'URUGUAY', 'Uruguay', 'URY', 858, 598 from dual union all
select 'UZ', 'UZBEKISTAN', 'Uzbekistan', 'UZB', 860, 998 from dual union all
select 'VU', 'VANUATU', 'Vanuatu', 'VUT', 548, 678 from dual union all
select 'VE', 'VENEZUELA', 'Venezuela', 'VEN', 862, 58 from dual union all
select 'VN', 'VIET NAM', 'Viet Nam', 'VNM', 704, 84 from dual union all
select 'VG', 'VIRGIN ISLANDS, BRITISH', 'Virgin Islands, British', 'VGB', 92, 1284 from dual union all
select 'VI', 'VIRGIN ISLANDS, U.S.', 'Virgin Islands, U.s.', 'VIR', 850, 1340 from dual union all
select 'WF', 'WALLIS AND FUTUNA', 'Wallis and Futuna', 'WLF', 876, 681 from dual union all
select 'EH', 'WESTERN SAHARA', 'Western Sahara', 'ESH', 732, 212 from dual union all
select 'YE', 'YEMEN', 'Yemen', 'YEM', 887, 967 from dual union all
select 'ZM', 'ZAMBIA', 'Zambia', 'ZMB', 894, 260 from dual union all
select 'ZW', 'ZIMBABWE', 'Zimbabwe', 'ZWE', 716, 263 from dual
/