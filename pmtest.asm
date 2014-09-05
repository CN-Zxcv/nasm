%include "pm.asm"
;%include "da_.asm"

;org 0100h
org 07c00h

jmp LABEL_BEGIN

[SECTION .gdt]
LABEL_GDT:	
	Descriptor 	0, 	0, 	0	; 空描述符
LABEL_DESC_CODE32:
   	Descriptor 	0, 	SegCode32Len - 1,	DA_C + DA_32	;代码段，32位
LABEL_DESC_VIDEO:
   	Descriptor 	0b8000h, 	0ffffh, 	DA_DRW	;显存首地址

GdtLen	equ	$ - LABEL_GDT	;GDT长度
GdtPtr	dw 	GdtLen	;GDT界限
	dd 	0	;GDT基地址

;GDT 选择子
SelectorCode32	equ LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo	equ LABEL_DESC_VIDEO - LABEL_GDT

[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	ax,	cs
	mov	ds,	ax
	mov	es,	ax
	mov	ss,	ax
	mov	sp,	0100h

	;初始化32位代码段描述符
	xor	eax,	eax
	mov	ax,	cs
	shl	eax,	4
	add	eax,	LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2],    ax
	shr	eax,	16
	mov	byte [LABEL_DESC_CODE32 + 4],    al
	mov	byte [LABEL_DESC_CODE32 + 7],    ah

	;为加载gdtr做准备
	xor	eax,	eax
	mov	ax,	ds
	shl	eax,	4
	add	eax,	LABEL_GDT
	mov	dword	[GdtPtr + 2],	eax

	;加载gdtr
	lgdt	[GdtPtr]

	;关中断
	cli

	;打开地址线A20
	in	al,	92h
	or	al,	00000010b
	out	92h,	al

	;准备切换到保护模式
	mov	eax,	cr0
	or	eax,	1
	mov	cr0,	eax

	;真正进入保护模式
	jmp	dword	SelectorCode32:0

[SECTION .s32]	;32位代码段，由实模式跳入
[BITS	32]
LABEL_SEG_CODE32:
	mov	ax,	SelectorVideo
	mov	gs,	ax	;视频段选择子
	mov	edi,	(80 *10 + 0) * 2	;屏幕第10行第0列
	mov	ah,	0ch	;0000:黑底	1100:红字
	mov	al,	'P'
	mov	[gs:edi],	ax

	;结束
	jmp	$

SegCode32Len	equ	$ - LABEL_SEG_CODE32
