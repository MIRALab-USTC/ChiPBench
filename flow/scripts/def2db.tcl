source $::env(SCRIPTS_DIR)/util.tcl
proc def2db {def_path db_path} {
    read_lef $::env(TECH_LEF)
    read_lef $::env(SC_LEF)
    if {[env_var_exists_and_non_empty ADDITIONAL_LEFS]} {
      foreach lef $::env(ADDITIONAL_LEFS) {
        read_lef $lef
      }
    }
    read_def $def_path
    write_db $db_path

}

def2db $::env(TARGET_DEF_PATH) $::env(RESULTS_DIR)/$::env(TARGET_DB_PATH)