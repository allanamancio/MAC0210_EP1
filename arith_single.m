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
    if (num >= (Nmax + ulp(2^127)/2) | num == 0 | num < Nmin)
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
        if (neg == 1) x *= -1;
        endif
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

# Esta função retorna um vetor com os bits de um dado número normalizado.
function result = dectobin(num)
    # Vetor representando o número em ponto flutuante no formato padrão IEEE Single
    result = zeros(1, 25);
    
    # Encontrando o sinal
    if (num < 0)
        num *= -1;
        result(1) = 1;
    endif

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

# Realiza a soma arredonda de dois números em pontos flutuantes.
function result = sumround(num1, num2, rounding)
    # Caso os números não estejam em ponto flutuante:
    num1 = normalize_ray(num1, rounding);
    num2 = normalize_ray(num2, rounding);

    # Erro ou delegação
    if (num1 == 0 | num2 == 0)
        result = 0;
        disp("A conta não pode ser efetuada, pois pelo menos um dos números não é normalizável.");
        break;
    elseif (num1*num2 < 0)
        if (num1 < 0) result = subround(num2, -num1, rounding);
        else result = subround(num1, -num2, rounding);
        endif
        return;
    endif

    neg = 0;
    # Números negativos
    if (num1 < 0)
        num1 *= -1;
        num2 *= -1;
        neg = 1;
    endif

    # Representação dos números acima em bits
    bits_num1 = dectobin(num1); 
    bits_num2 = dectobin(num2);

    # Bits auxiliares
    guardbit1 = 0;
    guardbit2 = 0;
    stickybit = 0;

    # Configurando o maior e o menor número de forma que:
    # num1 >= num2 e bits_num1 >= bits_num2
    if (bits_num1(2) < bits_num2(2))
        # Troca de vetores
        aux = bits_num1;
        bits_num1 = bits_num2;
        bits_num2 = aux;
        # Troca de variáveis
        aux = num1;
        num1 = num2;
        num2 = aux;
    endif

    places_shifted = bits_num1(2) - bits_num2(2); # Diferença de expoentes
        
    significand1 = num1/(2^bits_num1(2)); # Primeiro significando
        
    # Significando 2 com o mesmo expoente do significando 1:

    # --- OBTENÇÃO DO SIGNIFICANDO 2 (início) ---

    significand2 = 2^(-places_shifted); # Hidden bit
    i = places_shifted + 1;
    j = 3; # Primeira casa binária

    # Deslocando os 23 bits de precisão no novo expoente (se preciso)
    while (i <= 23)
        if (bits_num2(j) == 1) significand2 += 2^(-i);
        endif
        i += 1;
        j += 1;
    endwhile

    # Preenchendo os bits auxiliares
    if (25 - j == 0)
        guardbit1 = bits_num2(j);
        significand2 += guardbit1*2^(-i);
    elseif (25 - j == 1)
        guardbit1 = bits_num2(j);
        guardbit2 = bits_num2(j+1);
        significand2 += (guardbit1*2^(-i) + guardbit2*2^(-(i+1)));
    elseif (25 - j >= 2)
        guardbit1 = bits_num2(j);
        guardbit2 = bits_num2(j+1);
        significand2 += (guardbit1*2^(-i) + guardbit2*2^(-(i+1)));
        j += 2;
        i += 2;

        # sticky bit
        while (j <= 25)
            if (bits_num2(j) == 1)
                stickybit = 1;
                significand2 += stickybit*2^(-i);
                break;
            endif
            j += 1;
        endwhile
    endif

    # --- OBTENÇÃO DO SIGNIFICANDO 2 (fim) ---

    # Somando os significandos
    significandsum = significand1 + significand2;

    d = 0; # Deslocamento
    if (significandsum >= 2)
        significandsum /= 2; # Tornando o hidden bit igual a 1
        d = 1;
    endif

    # Arredondando
    significandsum = normalize_ray(significandsum, rounding);

    # Soma
    result = significandsum*2^(bits_num1(2) + d);
    if (neg == 1) result *= -1;
    endif

    # Guards bits e Sticky bit
    disp("Guard bit 1:");
    disp(guardbit1);
    disp("Guard bit 2:");
    disp(guardbit2);
    disp("Sticky bit:");
    disp(stickybit);

endfunction

# Realiza a subtração arredonda de dois números em pontos flutuantes
function result = subround(num1, num2, rounding)
    # Caso os números não estejam em ponto flutuante:
    num1 = normalize_ray(num1, rounding);
    num2 = normalize_ray(num2, rounding);

    # Erro ou delegação
    if (num1 == 0 | num2 == 0)
        result = 0;
        disp("A conta não pode ser efetuada, pois pelo menos um dos números não é normalizável.");
        break;
    elseif (num1*num2 < 0)
        result = sumround(num1, -num2, rounding);
        return;
    elseif (num1 == num2)
        result = 0;
        disp("A conta não pode ser efetuada, pois ela resulta em 0, um número subnormal.");
        break;
    endif

    # Deixando o primeiro termo positivo e o segundo negativo
    # (-a) - (-b) => b - a
    # ou
    # (a) - (b) => a - b
    num2 *= -1;

    # Representação dos números acima em bits_num1
    bits_num1 = dectobin(num1); 
    bits_num2 = dectobin(num2);

    # Bits auxiliares
    guardbit1 = 0;
    guardbit2 = 0;
    stickybit = 0;

    # Configurando o "maior" e o "menor" número de forma que:
    # num1 >= num2 e bits_num1 >= bits_num2 "expoentemente" falando.
    if (bits_num1(2) < bits_num2(2))
        # Troca de vetores
        aux = bits_num1;
        bits_num1 = bits_num2;
        bits_num2 = aux;
        # Troca de variáveis
        aux = num1;
        num1 = num2;
        num2 = aux;
    endif

    places_shifted = bits_num1(2) - bits_num2(2); # Diferença de expoentes
        
    significand1 = num1/(2^bits_num1(2)); # Primeiro significando

    # Significando 2 com o mesmo expoente do significando 1:

    # --- OBTENÇÃO DO SIGNIFICANDO 2 (início) ---

    significand2 = 2^(-places_shifted); # Hidden bit
    i = places_shifted + 1;
    j = 3; # Primeira casa binária

    # Deslocando os 23 bits de precisão no novo expoente (se preciso)
    while (i <= 23)
        if (bits_num2(j) == 1) significand2 += 2^(-i);
        endif
        i += 1;
        j += 1;
    endwhile

    # Preenchendo os bits auxiliares
    if (25 - j == 0)
        guardbit1 = bits_num2(j);
        significand2 += guardbit1*2^(-i);
    elseif (25 - j == 1)
        guardbit1 = bits_num2(j);
        guardbit2 = bits_num2(j+1);
        significand2 += (guardbit1*2^(-i) + guardbit2*2^(-(i+1)));
    elseif (25 - j >= 2)
        guardbit1 = bits_num2(j);
        guardbit2 = bits_num2(j+1);
        significand2 += (guardbit1*2^(-i) + guardbit2*2^(-(i+1)));
        j += 2;
        i += 2;

        # sticky bit
        while (j <= 25)
            if (bits_num2(j) == 1)
                stickybit = 1;
                significand2 += stickybit*2^(-i);
                break;
            endif
            j += 1;
        endwhile
    endif

    if (bits_num2(1) == 1) significand2 *= -1;
    endif

    # --- OBTENÇÃO DO SIGNIFICANDO 2 (fim) ---

    # Somando os significandos
    significandsum = significand1 + significand2;

    d = 0; # Deslocamento
    while (abs(significandsum) < 1)
        significandsum *= 2; # Tornando o hidden bit igual a 1
        d = 1;
    endwhile

    # Arredondando
    significandsum = normalize_ray(significandsum, rounding);

    # Somando
    result = significandsum*2^(bits_num1(2) - d);

    # Guards bits e Sticky bit
    disp("Guard bit 1:");
    disp(guardbit1);
    disp("Guard bit 2:");
    disp(guardbit2);
    disp("Sticky bit:");
    disp(stickybit);

endfunction
