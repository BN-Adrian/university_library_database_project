DECLARE
    v_amenda NUMBER;
    v_id_utilizator NUMBER := 1; -- ID-ul utilizatorului de test
    v_isbn VARCHAR2(20) := '9780747532743'; -- ISBN-ul cărții de test
    v_nume_utilizator VARCHAR2(50) := 'Novel User';
    v_facultate VARCHAR2(50) := 'Literature';
    v_telefon VARCHAR2(15) := '0123456789';
    v_numar_carti_disponibile NUMBER;
    v_numar_carti_imprumutate NUMBER;
    v_poate_imprumuta BOOLEAN;
    v_premiat NUMBER;
    v_data_imprumut DATE := SYSDATE - 20; -- Împrumut acum 20 de zile
    v_data_retur_normal DATE := SYSDATE - 5; -- Returnare fără întârziere
    v_data_retur_tardiv DATE := SYSDATE + 5; -- Returnare cu întârziere de 5 zile
    v_status_librarie VARCHAR2(10);
BEGIN
    -- Verificăm dacă librăria este deschisă
    v_status_librarie := librarie_deschisa;
    DBMS_OUTPUT.PUT_LINE('Statusul librăriei: ' || v_status_librarie);

    -- Împrumut și returnare carte (tranzacție)
    IF v_status_librarie = 'Deschis' THEN
        BEGIN
            gestionare_imprumuturi.imprumuta_carte(v_isbn, v_id_utilizator, v_data_imprumut);
            DBMS_OUTPUT.PUT_LINE('Carte imprumutata.');

            gestionare_imprumuturi.returneaza_carte(v_isbn, v_id_utilizator, v_data_retur_normal);
            DBMS_OUTPUT.PUT_LINE('Carte returnata fara intarziere.');

            gestionare_imprumuturi.returneaza_carte(v_isbn, v_id_utilizator, v_data_retur_tardiv);
            DBMS_OUTPUT.PUT_LINE('Carte returnata cu intarziere.');

            v_amenda := gestionare_imprumuturi.calculeaza_amenda(v_isbn, v_id_utilizator);
            DBMS_OUTPUT.PUT_LINE('Amenda calculata pentru intarziere: ' || TO_CHAR(v_amenda) || ' lei');

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                DBMS_OUTPUT.PUT_LINE('A aparut o eroare: ' || SQLERRM);
        END;
    ELSE
        DBMS_OUTPUT.PUT_LINE('Libraria este inchisa. Nicio tranzactie nu a fost efectuata.');
    END IF;

    -- Actualizare carte (tranzacție)
    BEGIN
        actualizeaza_carte(v_isbn, 'Harry Potter and the Philosopher''s Stone Updated', 1);
        DBMS_OUTPUT.PUT_LINE('Carte actualizata.');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('A aparut o eroare la actualizarea cartii: ' || SQLERRM);
    END;

    -- Înregistrare utilizator (tranzacție)
    BEGIN
        inregistreaza_utilizator(v_nume_utilizator, v_facultate, v_telefon);
        DBMS_OUTPUT.PUT_LINE('Utilizator inregistrat.');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('A aparut o eroare la inregistrarea utilizatorului: ' || SQLERRM);
    END;

    -- Funcții generale (tranzacție implicită)
    BEGIN
        v_numar_carti_disponibile := numar_carti_disponibile(1);  -- Presupunem categoria 1
        DBMS_OUTPUT.PUT_LINE('Numar carti disponibile: ' || v_numar_carti_disponibile);

        v_numar_carti_imprumutate := numar_carti_imprumutate(v_id_utilizator);
        DBMS_OUTPUT.PUT_LINE('Numar carti imprumutate de utilizatorul ' || v_id_utilizator || ': ' || v_numar_carti_imprumutate);

        v_poate_imprumuta := poate_imprumuta(v_id_utilizator);
        DBMS_OUTPUT.PUT_LINE('Utilizatorul ' || v_id_utilizator || ' poate imprumuta mai multe carti: ' || CASE WHEN v_poate_imprumuta THEN 'Da' ELSE 'Nu' END);

        v_premiat := premiaza_studentul_lunii(2023, 5);  -- Exemplu pentru luna Mai 2023
        IF v_premiat IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('Studentul premiat pentru luna este: ' || v_premiat);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Niciun student nu a fost premiat in luna respectiva.');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('A aparut o eroare: ' || SQLERRM);
    END;

    -- Verificarea intrărilor în logurile de împrumuturi și returnări
    BEGIN
        FOR rec IN (SELECT tip_activitate, isbn, id_utilizator, data_operatie, observatii FROM log_imprumuturi)
        LOOP
            DBMS_OUTPUT.PUT_LINE('Log: ' || rec.tip_activitate || ', ISBN: ' || rec.isbn || ', Utilizator: ' || rec.id_utilizator || ', Data: ' || TO_CHAR(rec.data_operatie, 'DD-MON-YYYY') || ', Observații: ' || rec.observatii);
        END LOOP;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('A aparut o eroare la verificarea logurilor: ' || SQLERRM);
    END;

    -- Verificarea amenzilor aplicate
    BEGIN
        FOR rec IN (SELECT id_utilizator, isbn, data_amenda, suma_amenda, descriere FROM amenzile_utilizator)
        LOOP
            DBMS_OUTPUT.PUT_LINE('Amenda pentru utilizatorul ' || rec.id_utilizator || ' pentru cartea ' || rec.isbn || ' de ' || rec.suma_amenda || ' lei, ' || rec.descriere);
        END LOOP;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('A aparut o eroare la verificarea amenzilor: ' || SQLERRM);
    END;

END;
/
