#ifndef JAMMING_EXP_H
#define JAMMING_EXP_H

#define JMR_DEBUG 0
#define USE_CCA 0

#define PACKETS_COUNT 6000

#define NORMAL_INTERVAL 10

// 20byte
typedef nx_struct regular_msg {
	nx_uint16_t packet_num;
	nx_uint16_t packet_num2;
	nx_uint16_t packet_num3;
	nx_uint16_t packet_num4;
	nx_uint16_t packet_num5;
	nx_uint16_t packet_num6;
	nx_uint16_t packet_num7;
	nx_uint16_t packet_num8;
	nx_uint16_t packet_num9;
	nx_uint16_t packet_num10;
} regular_msg_t;

enum {
	AM_JAMMING_EXP_MSG = 6,
};

#endif
