class FilterByName extends Filter{
    private String[] name;
    //int i=0;
    public FilterByName(String... name) {
        this.name = name;
    }
    public boolean accept(Song music) {
        for(int i=0;i<name.length;i++){
            if(name[i].equals(music.getName())){
                return true;
            }
        }
        return false;
    }
}


/*باید فقط اسم یه آهنگ رو بگیریم و فیلترش کنیم نه چندتا آهنگ

    public FilterByName(String name) {
        this.name = name;
    }

    @Override
    public boolean accept(Song song) {
        return name.equalsIgnoreCase(song.getName());
    }
}*/