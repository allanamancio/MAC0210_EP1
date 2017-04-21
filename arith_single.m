1;
# Allan Rocha e Igor Fratel
# n. 9761614 | n. 9793565
# Parte 1: Aritmética de Ponto Flutuante

format longp

function ... = ulp(num)

endfunction

# Esta função recebe um número real e retorna a sua representação,
# se existir, no intervalo normalizado no formato IEEE SINGLE.
function b = dectobin(num)
    # Nmax e Nmin no formato IEE SINGLE
    Nmax = 1.11111111111111111111111*2^127
    Nmin = 1.00000000000000000000000*2^-126
    
    # Representação do ponto flutuante no vetor
    b = zeros(1, 32);

    # Número negativo
    if (num < 0)
        num *= -1;
        b(0) = 1;
    endfunction

    # Divisão do número em parte inteira e fracionária
    partInt = floor();
    partFract = num - partInt;

    # Conversão (decimal -> binária) da parte inteira
    
    # Caso em que o número é infinito ou subnormal
    if (num >= (Nmax + ulp(2^127)/2))
        b = 255;
        return;
    elseif (num <= Nmin)
        # *TERMINAR DE IMPLEMENTAR
        b = 0;
        return;
    endif

    i = Nmax;
    while (i >= 0)
        if (2^i <= Num)

endfunction
