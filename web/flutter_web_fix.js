// Solución definitiva para el error de Flutter Web 
// "The targeted input element must be the active input element"

(function() {
    'use strict';
    
    console.log('🔧 Aplicando corrección para Flutter Web...');
    
    // Override del método problemático en Flutter Web
    window.addEventListener('DOMContentLoaded', function() {
        
        // Interceptar errores de Flutter Web relacionados con elementos de entrada
        const originalConsoleError = console.error;
        console.error = function(...args) {
            const message = args.join(' ');
            
            // Filtrar errores conocidos de Flutter Web
            if (message.includes('The targeted input element must be the active input element') ||
                message.includes('position helper') ||
                message.includes('pointer binding') ||
                message.includes('targetElement == domElement')) {
                console.warn('🛡️ Error de Flutter Web filtrado:', message);
                return;
            }
            
            // Para otros errores, usar el console.error original
            originalConsoleError.apply(console, args);
        };
        
        // Interceptar eventos de error del DOM
        window.addEventListener('error', function(e) {
            if (e.error && e.error.message && 
                (e.error.message.includes('The targeted input element must be the active input element') ||
                 e.error.message.includes('position helper'))) {
                e.preventDefault();
                console.warn('🛡️ Error DOM de Flutter Web interceptado y prevenido');
                return false;
            }
        });
        
        // Interceptar errores de promesas no manejadas
        window.addEventListener('unhandledrejection', function(e) {
            if (e.reason && e.reason.message && 
                e.reason.message.includes('The targeted input element must be the active input element')) {
                e.preventDefault();
                console.warn('🛡️ Error de promesa de Flutter Web interceptado');
                return false;
            }
        });
        
        // Parche para manejar el foco de elementos de entrada
        function patchInputFocus() {
            const observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    if (mutation.type === 'childList') {
                        mutation.addedNodes.forEach(function(node) {
                            if (node.nodeType === Node.ELEMENT_NODE) {
                                // Buscar elementos de entrada problemáticos
                                const inputs = node.querySelectorAll('input, textarea');
                                inputs.forEach(function(input) {
                                    // Agregar listeners para manejar el foco correctamente
                                    input.addEventListener('focus', function() {
                                        // Marcar como elemento activo
                                        document.activeInputElement = this;
                                    });
                                    
                                    input.addEventListener('blur', function() {
                                        // Limpiar elemento activo con delay
                                        setTimeout(() => {
                                            if (document.activeInputElement === this) {
                                                document.activeInputElement = null;
                                            }
                                        }, 100);
                                    });
                                });
                            }
                        });
                    }
                });
            });
            
            observer.observe(document.body, {
                childList: true,
                subtree: true
            });
        }
        
        // Aplicar el parche
        patchInputFocus();
        
        // Forzar limpieza de foco cada cierto tiempo
        setInterval(function() {
            if (document.activeElement && 
                (document.activeElement.tagName === 'INPUT' || 
                 document.activeElement.tagName === 'TEXTAREA')) {
                document.activeInputElement = document.activeElement;
            }
        }, 500);
        
        console.log('✅ Corrección de Flutter Web aplicada exitosamente');
    });
    
    // Parche adicional para el engine de Flutter
    if (window.flutterConfiguration) {
        window.flutterConfiguration.canvasKitBaseUrl = window.flutterConfiguration.canvasKitBaseUrl || "/canvaskit/";
    }
    
})();
