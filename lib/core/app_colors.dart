import 'package:flutter/material.dart';

class AppColors {
  // --- IDENTIDAD Y ESTRUCTURA BASE ---
  static const Color primary = Color(0xFF3730A3);       // Índigo corporativo (Headers, botones y marca)
  static const Color secondary = Color(0xFF2563EB);     // Azul Tech (VLANs, enlaces)
  static const Color background = Color(0xFFF4F6FB);    // Gris frío de fondo
  static const Color surface = Color(0xFFFFFFFF);       // Blanco puro para tarjetas
  static const Color border = Color(0xFFE2E8F0);        // Bordes suaves

  // --- TEXTOS ---
  static const Color textPrimary = Color(0xFF0F172A);   // Títulos, IPs e identificadores
  static const Color textSecondary = Color(0xFF64748B); // MACs, fechas y metadatos

  // --- ESTADOS OPERATIVOS ---
  // Activo (Verde Esmeralda)
  static const Color statusActive = Color(0xFF059669);
  static const Color statusActiveBg = Color(0xFFE6F4EA);

  // Mantenimiento / Pausa (Ámbar)
  static const Color statusWarning = Color(0xFFD97706);
  static const Color statusWarningBg = Color(0xFFFEF3C7);

  // Crítico / Caído / Inactivo (Rojo Carmesí)
  static const Color statusCritical = Color(0xFFDC2626);
  static const Color statusCriticalBg = Color(0xFFFEE2E2);

  // --- TIPOLOGÍAS DE EQUIPOS (ÍCONOS Y CATEGORÍAS) ---
  static const Color router = Color(0xFF2563EB);        // Azul
  static const Color switchNet = Color(0xFF3730A3);     // Índigo
  static const Color server = Color(0xFFDC2626);        // Rojo carmesí
  static const Color accessPoint = Color(0xFFD97706);   // Ámbar
  static const Color pc = Color(0xFF0284C7);            // Cían
  static const Color laptop = Color(0xFF0EA5E9);        // Azul cielo
  static const Color printer = Color(0xFF78350F);       // Marrón
  static const Color phone = Color(0xFFDB2777);         // Rosa
}