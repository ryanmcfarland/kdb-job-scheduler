// Simple logging

.log.message:{[typ;msg]
    str:"[ 2021.03.26T16:22:58.038 desktop-ibii84o ryanm (374416|67108864|0) ] ";
    0N!raze str,typ,": ",msg;};

.log.info:.log.message["INFO"];
.log.error:.log.message["ERROR"];