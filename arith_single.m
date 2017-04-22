# Allan Rocha e Igor Fratel
# n. 9761614 | n. 9793565
# Parte 1: Aritmética de Ponto Flutuante

format long

# Esta função recebe uma potência de base 2 e retorna a ULP.
function exE = ulp(E)
    exE = (2^-23)*E;
endfunction

# Esta função recebe um número real e retorna a sua representação,
# se existir, no intervalo normalizado no formato IEEE SINGLE.
# O arrendondamento é determinado pela string <rounding>.
function n = normalize_ray(num, rounding)
    # Nmax e Nmin no formato IEE SINGLE
    Nmax = 3.40282346638529e+38; # 1.11111111111111111111111*2^127
    Nmin = 1.17549435082229e-38; # 1.00000000000000000000000*2^-126;
    
    # Número negativo para positivo
    neg = 0;
    if (num < 0)
        num *= -1;
        neg = 1;
    endif
    
    # Caso em que o número é infinito, zero ou subnormal
    # (Na parte do arredondamento pode surgir esses casos também)
    if (num >= (Nmax + ulp(2^127)/2) | num == 0 | num < 2^-126)
        n = 0;
        return;
    endif

    # Normalizando o número preenchendo as 23 casas de precisão
    exponent_found = 0;
    x = 0; # Número normalizado
    p = 0; # Precisão
    i = 127; # Potência máxima
    while (i >= -149 & p < 23)
        lastbit = 0;
        if (exponent_found == 1) p += 1;
        endif
        if (2^i <= num)
            num -= 2^i;
            x += 2^i;
            if (exponent_found == 0)
                E = i;
                exponent_found = 1;
            else
                lastbit = 1;
            endif
        endif
        i -= 1;
    endwhile

    # O número já está normalizado
    if (num == 0)
        n = x;
        return;
    endif

    # O número ainda não está normalizado

    # x+ e x-
    if (neg == 0)
        xplus = x + ulp(2^E);
        xminus = x;
    else
        xplus = x;
        xminus = x + ulp(2^E);
    endif
    
    # Arredondamento
    if (strcmp(rounding, "nearest"))
        if (2^i <= num)
            # Arrendondamento pra cima ou TIE
            num -= 2^i;
            if (num != 0)
                if (neg == 0)
                    n = xplus;
                else
                    n = xminus;
                endif
            else
                # TIE
                if (lastbit == 0)
                    n = x;
                else
                    if (neg == 0)
                        n = xminus;
                    else
                        n = xplus;
                    endif
                endif
            endif
        else
            # Arrendondamento pra baixo
            n = x;
        endif
    elseif (strcmp(rounding, "infinite"))
        # Caso em que o número é infinito
        if (xplus > Nmax) n = 0;
        else n = xplus;
        endif
    elseif (strcmp(rounding, "-infinite"))
        # Caso em que o numero é infinito
        if (xminus > Nmax) n = 0;
        else n = xminus;
        endif
    elseif (strcmp(rounding, "zero"))
        n = x;
    endif
    
    # Voltando o número positivo pro negativo
    if (neg == 1)
        n *= -1;
    endif
    
endfunction

# Esta função retorna um vetor com os bits de um dado número normalizado
function result = dectobin(num)
    # Vetor representando o número em ponto flutuante no formato padrão IEEE Single
    result = zeros(1, 25);
    
    # Encontrando o sinal
    if (num < 0)
        result(1) = 1;

    i = 127; # Potência máxima
    # Encontrando a potência
    while (i >= -126)
        if (2^i <= num)
            num -= 2^i;
            result(2) = i;
            break;
        endif
        i -= 1;
    endwhile

    i -= 1;

    p = 0; # Precisão
    # Encontrando os 23 bits de precisão
    while (p < 23)
        p += 1;
        if (2^i <= num)
            num -= 2^i;
            result(2 + (result(2) - i)) = 1; # bits 1
        endif
        i -= 1;
    endwhile

endfunction

# Realiza a soma arredonda de dois números em pontos flutuantes
function result = sumround(num1, num2)
    # Caso os números não estejam em ponto flutuante:
    num1 = normalize_ray(num1);
    num2 = normalize_ray(num2);
    # Representação dos números acima em bits
    bits_num1 = dectobin(num1);
    bits_num2 = dectobin(num2);

    # Bits auxiliares
    guardbit1 = 0;
    guardbit2 = 0;
    stingybit = 0;

    # Caso em que os expoentes são iguais:
    if (bits_num1(2) == bits_num2(2))
        significand1 = num1/(2^bits_num1(2));
        significand2 = num2/(2^bits_num2(2));
        significandsum = significand1 + significand2;
        # Eliminação do último bit de precisão
        if (bits_num1(25) + bits_num2(25) == 1)
            significandsum -= 2^-23;
        endif
        significandsum /= 2;
        result = significandsum*2^(bits_num1(2)+1)
    # Caso em que os expoentes são diferentes:
    else
        if (bits_num1(2) > bits_num2(2))
            places_shifted = bits_num1(2) - bits_num2(2);
            significand1 = num1/(2^bits_num1(2));
            significand2 = num2/(2^bits_num2(2));
            # Posicionando o significando 2 com o significando 1:
            significand2 /= 2^places_shifted;

            # FAZENDO A PARTE DE DETERMINAR OS BITS GUARDA E STINGY
            # ALÉM DE ELIMINAR O DESNECESSRIOS NOS SIGNIFICANDOS

        else
            places_shifted = bits_num2(2) - bits_num1(2);
        endif
    endif

endfunction
