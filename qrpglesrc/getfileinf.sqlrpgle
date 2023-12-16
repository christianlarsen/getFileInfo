**free
ctl-opt main(main) dftactgrp(*no) actgrp(*caller);

dcl-s error_t ind template;

dcl-ds file_t qualified template;
    field_short varchar(10);
    field varchar(128);
    type varchar(8);
    length int(10);
    numeric_scale int(10);
    column_text varchar(50);
    column_heading varchar(60);
end-ds;

dcl-proc main;
    dcl-pi *n;
        library char(10) const;
        file char(10) const;
    end-pi;
    dcl-s error like(error_t);
    dcl-s numfields zoned(3);
    dcl-ds fileDS likeds(file_t) dim(*auto:100);

    error = getFileInfo(library:file:fileDS:numfields);
    if error = *on;
        snd-msg 'Error retrieving file information.';
    endif;
    %elem(fileDS:*keep) = numfields;

end-proc;

dcl-proc getFileInfo;
    dcl-pi *n like(error_t);
        library char(10) const;
        file char(10) const;
        fileDS likeds(file_t) dim(100) options(*varsize);
        numfields zoned(3);
    end-pi;
    dcl-s error like(error_t);
    dcl-s maxRows zoned(3) inz(100);

    clear fileDS;
    numfields = 0;

    monitor;
        exec sql
            declare c1 cursor for
                select  system_column_name , 
                        column_name , 
                        data_type , 
                        length ,
                        coalesce(numeric_scale, 0),
                        coalesce(column_text, ' '),
                        coalesce(column_heading, ' ')
                from qsys2.syscolumns2
                where   system_table_name = :file and
                        system_table_schema = :library;

        exec sql
            open c1;

        exec sql
            fetch c1 for :maxRows rows into :fileDS;
        
        exec sql 
            get diagnostics :numfields = row_count;

        exec sql
            close c1;

    on-error;
        error = *on;
        return error;
    endmon;

    if numfields <= 0;
        error = *on;
    endif;

    return error;

end-proc;

